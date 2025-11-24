[CmdletBinding()]
param(
  [string]$ConfigPath = "config/metrics_config.yaml",
  [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

function Write-Info($m){ Write-Host "[Metrics] $m" -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host "[Metrics] $m" -ForegroundColor Yellow }
function Write-Err($m){ Write-Host "[Metrics] $m" -ForegroundColor Red }

# Minimal YAML parser for simple key: value pairs; prefers ConvertFrom-Yaml if available
function Read-MetricsConfig([string]$path){
  if(-not (Test-Path $path)) { throw "Config not found: $path" }
  $raw = Get-Content $path -Raw
  try {
    if(Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue){
      return $raw | ConvertFrom-Yaml
    }
  } catch { Write-Warn "ConvertFrom-Yaml failed, falling back to simple parser: $_" }
  $cfg = @{}
  foreach($line in ($raw -split "`n")){
    $t = ($line -replace "#.*$"," ").Trim()
    if([string]::IsNullOrWhiteSpace($t)) { continue }
    if($t -notmatch ":") { continue }
    $k,$v = $t.Split(":",2)
    $k = $k.Trim()
    $v = $v.Trim().Trim('"')
    if($v -match '^(true|false)$'){ $cfg[$k] = [System.Convert]::ToBoolean($v) }
    elseif($v -match '^[0-9]+(\.[0-9]+)?$'){ $cfg[$k] = [double]$v }
    else { $cfg[$k] = $v }
  }
  return [pscustomobject]$cfg
}

function Get-FileSha256([string]$path){
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $fs = [System.IO.File]::OpenRead($path)
  try {
    $hash = $sha.ComputeHash($fs)
    return -join ($hash | ForEach-Object { $_.ToString('x2') })
  } finally { $fs.Dispose(); $sha.Dispose() }
}

function Compress-Gzip([string]$inputPath, [string]$outputPath){
  $inStream = [System.IO.File]::OpenRead($inputPath)
  $outStream = [System.IO.File]::Create($outputPath)
  try {
    $gzip = New-Object System.IO.Compression.GzipStream($outStream, [System.IO.Compression.CompressionMode]::Compress)
    try { $inStream.CopyTo($gzip) } finally { $gzip.Dispose() }
  } finally { $inStream.Dispose(); $outStream.Dispose() }
}

function Ensure-Dir([string]$dir){ if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null } }

function Rotate-IfNeeded($cfg){
  $rawRoot = $cfg.logs_root
  $activeName = $cfg.raw_file
  $maxMb = [int]$cfg.max_file_size_mb
  $maxDays = if($cfg.PSObject.Properties.Name -contains 'max_days'){ [int]$cfg.max_days } else { 7 }

  Ensure-Dir $rawRoot
  $activePath = Join-Path $rawRoot $activeName
  if(-not (Test-Path $activePath)) { return $null }

  $fi = Get-Item $activePath
  $sizeMb = [math]::Round($fi.Length/1MB,2)
  $ageDays = (New-TimeSpan -Start $fi.CreationTime -End (Get-Date)).TotalDays

  $needsRotate = ($fi.Length -gt ($maxMb*1MB)) -or ($ageDays -gt $maxDays)
  if(-not $needsRotate) { return $null }

  $stamp = (Get-Date -Format 'yyyyMMdd_HHmm')
  $rotatedName = "success_rate_${stamp}.log"
  $rotatedPath = Join-Path $rawRoot $rotatedName

  Write-Info "Rotating: size=${sizeMb}MB age=${ageDays}d -> $rotatedName"
  Move-Item -Path $activePath -Destination $rotatedPath -Force
  # Create new empty active file
  New-Item -ItemType File -Path $activePath -Force | Out-Null
  return $rotatedPath
}

function Get-Latest-File([string]$dir, [string]$pattern){
  if(-not (Test-Path $dir)){ return $null }
  $files = Get-ChildItem -Path $dir -Filter $pattern -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  if($files -and $files.Count -gt 0){ return $files[0].FullName }
  return $null
}

function Aggregate-Window($cfg){
  $rawRoot = $cfg.logs_root
  $summaryDir = $cfg.summary_dir
  $interval = (""+$cfg.aggregation_interval).ToLower()
  Ensure-Dir $summaryDir

  $now = Get-Date
  switch($interval){
    'hourly' { $windowStart = $now.AddHours(-1) }
    'weekly' { $windowStart = $now.AddDays(-7) }
    default  { $windowStart = $now.AddDays(-1) }
  }

  # Candidate files: latest rotated .log within window + active raw file if exists
  $candidates = @()
  if(Test-Path $rawRoot){
    $candidates += (Get-ChildItem -Path $rawRoot -Filter '*.log' -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -ge $windowStart }).FullName
    $active = Join-Path $rawRoot $cfg.raw_file
    if(Test-Path $active){ $candidates += $active }
  }
  $candidates = $candidates | Select-Object -Unique
  if(-not $candidates -or $candidates.Count -eq 0){ Write-Warn "No raw files in aggregation window"; return $null }

  $total=0; $success=0; $fail=0
  foreach($file in $candidates){
    try {
      Get-Content $file -ErrorAction SilentlyContinue | ForEach-Object {
        $line = $_
        if([string]::IsNullOrWhiteSpace($line)){ return }
        $total++
        $l = $line.ToLower()
        if($l -match 'success\b' -or $l -match '\bok\b' -or $l -match '\bpassed\b' -or $l -match '"success"\s*:\s*true'){
          $success++
        } elseif($l -match 'fail\b' -or $l -match 'error\b' -or $l -match '"success"\s*:\s*false'){
          $fail++
        }
      }
    } catch { Write-Warn "Aggregation read error: $file :: $_" }
  }
  if($total -eq 0){ $rate = 0 } else { $rate = [math]::Round($success / [double]$total, 4) }

  $summaryCsv = Join-Path $summaryDir 'success_rate_summary.csv'
  if(-not (Test-Path $summaryCsv)){
    "timestamp,total,success,fail,success_rate" | Out-File $summaryCsv -Encoding utf8
  }
  $line = "{0},{1},{2},{3},{4}" -f ($now.ToString('o')),$total,$success,$fail,$rate
  Add-Content -Path $summaryCsv -Value $line

  return @{ summaryPath=$summaryCsv; total=$total; success=$success; fail=$fail; rate=$rate }
}

function Apply-Retention($cfg){
  $rawRoot = $cfg.logs_root
  $days = [int]$cfg.raw_retention_days
  $compress = [bool]$cfg.compress_old_raw
  if(-not (Test-Path $rawRoot)){ return }
  $cutoff = (Get-Date).AddDays(-$days)
  $files = Get-ChildItem -Path $rawRoot -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cutoff }
  foreach($f in $files){
    try {
      if($compress -and $f.Extension -ne '.gz'){
        $gz = "$($f.FullName).gz"
        if(-not (Test-Path $gz)){
          Compress-Gzip -inputPath $f.FullName -outputPath $gz
        }
        Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
        Write-Info "Compressed old raw: $($f.Name) -> $(Split-Path $gz -Leaf)"
      } else {
        Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
        Write-Info "Deleted old raw: $($f.Name)"
      }
    } catch { Write-Warn "Retention action failed for $($f.FullName): $_" }
  }
}

function Update-MetricsManifest($cfg, [string]$latestRawPath, [string]$latestSummaryPath){
  $manifestPath = $cfg.manifest_path
  $manifestDir = Split-Path $manifestPath -Parent
  Ensure-Dir $manifestDir
  $entries = @()
  if(Test-Path $manifestPath){
    try { $existing = Get-Content $manifestPath -Raw | ConvertFrom-Json; if($existing){ $entries = @($existing) } } catch { Write-Warn "Failed to read manifest: $_" }
  }
  $now = Get-Date
  $toAdd = @()
  if($latestRawPath -and (Test-Path $latestRawPath)){
    $fi = Get-Item $latestRawPath
    $toAdd += [pscustomobject]@{ path=$fi.FullName; sha256=(Get-FileSha256 $fi.FullName); size_bytes=$fi.Length; timestamp=$now.ToString('o') }
  }
  if($latestSummaryPath -and (Test-Path $latestSummaryPath)){
    $fi = Get-Item $latestSummaryPath
    $toAdd += [pscustomobject]@{ path=$fi.FullName; sha256=(Get-FileSha256 $fi.FullName); size_bytes=$fi.Length; timestamp=$now.ToString('o') }
  }
  if($toAdd.Count -gt 0){
    $entries += $toAdd
    # Keep last 200
    $entries = $entries | Select-Object -Last 200
    $entries | ConvertTo-Json -Depth 4 | Out-File $manifestPath -Encoding UTF8
    Write-Info "Manifest updated: $manifestPath"
  }
}

try {
  $cfg = Read-MetricsConfig $ConfigPath
  # Ensure required fields or set defaults
  if(-not ($cfg.PSObject.Properties.Name -contains 'logs_root')){ $cfg | Add-Member -NotePropertyName logs_root -NotePropertyValue 'C:\BladeOps\data\metrics\raw' }
  if(-not ($cfg.PSObject.Properties.Name -contains 'raw_file')){ $cfg | Add-Member -NotePropertyName raw_file -NotePropertyValue 'success_rate.log' }
  if(-not ($cfg.PSObject.Properties.Name -contains 'summary_dir')){ $cfg | Add-Member -NotePropertyName summary_dir -NotePropertyValue 'C:\BladeOps\data\metrics\summary' }
  if(-not ($cfg.PSObject.Properties.Name -contains 'manifest_path')){ $cfg | Add-Member -NotePropertyName manifest_path -NotePropertyValue 'C:\BladeOps\data\metrics\metrics_manifest.json' }
  if(-not ($cfg.PSObject.Properties.Name -contains 'compress_old_raw')){ $cfg | Add-Member -NotePropertyName compress_old_raw -NotePropertyValue $true }
  if(-not ($cfg.PSObject.Properties.Name -contains 'raw_retention_days')){ $cfg | Add-Member -NotePropertyName raw_retention_days -NotePropertyValue 30 }

  $rotated = Rotate-IfNeeded $cfg

  $agg = Aggregate-Window $cfg

  # Determine latest raw and summary files
  $latestRaw = $rotated
  if(-not $latestRaw){ $latestRaw = Get-Latest-File -dir $cfg.logs_root -pattern '*.log' }
  $latestSummary = if($agg){ $agg.summaryPath } else { Get-Latest-File -dir $cfg.summary_dir -pattern '*.csv' }

  Update-MetricsManifest -cfg $cfg -latestRawPath $latestRaw -latestSummaryPath $latestSummary

  Apply-Retention $cfg

  Write-Info "Done. LatestRaw='$latestRaw' LatestSummary='$latestSummary'"
  if($env:HARNESS_INCLUDE_METRICS_MANIFEST -ne '1'){
    Write-Info "Tip: set HARNESS_INCLUDE_METRICS_MANIFEST=1 to include metrics manifest in VerificationHarness artifacts."
  }
} catch {
  Write-Err "Metrics management failed: $_"
  exit 1
}
