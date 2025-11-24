param(
  [string[]]$SourceDirs = @(
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop"
  ),
  [Parameter(Mandatory=$true)][string]$Pc5Path,
  [Parameter(Mandatory=$true)][string]$NasPath,
  [switch]$DryRun,
  [switch]$AlsoCopyToNas,
  [int]$MinSizeMB = 0
)

$ErrorActionPreference = 'Stop'

# Classify non?mission?critical by extensions
$ExtGroups = @{
  Installers = @('.exe','.msi','.msix','.pkg');
  Archives   = @('.zip','.7z','.rar','.tar','.gz','.bz2','.xz');
  Models     = @('.gguf','.safetensors','.bin','.onnx');
  DiskImages = @('.iso','.img');
  Media      = @('.mp4','.mov','.mkv','.avi','.mp3','.wav');
  LogsTmp    = @('.log','.tmp','.bak');
}
$AllExt = $ExtGroups.Values | ForEach-Object { $_ } | Select-Object -Unique

# Ensure destinations
foreach ($p in @($Pc5Path,$NasPath)) { if ($p -and -not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }

$items = @()
foreach ($root in $SourceDirs) {
  if (-not (Test-Path $root)) { Write-Host "[skip] $root" -ForegroundColor DarkYellow; continue }
  $files = Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $AllExt -contains $_.Extension.ToLower() } |
    Where-Object { ($_.Length/1MB) -ge $MinSizeMB }
  $items += $files
}

if (-not $items) { Write-Host "No candidates found." -ForegroundColor Yellow; exit 0 }

$log = @()

function Ensure-DestDir([string]$base,[System.IO.FileInfo]$f){
  $rel = try { $f.FullName.Substring([System.IO.Path]::GetPathRoot($f.FullName).Length) } catch { $f.Name }
  $dest = Join-Path $base (Split-Path $rel -Parent)
  if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }
  return (Join-Path $dest $f.Name)
}

$op = if ($DryRun) { "DRYRUN" } else { "MOVE" }
Write-Host "[$op] Transferring $($items.Count) files to PC5: $Pc5Path" -ForegroundColor Cyan

foreach ($f in $items) {
  $target = Ensure-DestDir -base $Pc5Path -f $f
  if ($DryRun) {
    Write-Host "? would move: $($f.FullName) -> $target" -ForegroundColor Gray
  } else {
    try {
      Move-Item -LiteralPath $f.FullName -Destination $target -Force
    } catch {
      # Cross-device lock fallback: copy then remove
      Copy-Item -LiteralPath $f.FullName -Destination $target -Force
      Remove-Item -LiteralPath $f.FullName -Force
    }
  }
  $log += [pscustomobject]@{ Src=$f.FullName; Dest=$target; SizeMB=[math]::Round($f.Length/1MB,2); Ext=$f.Extension }
}

if ($AlsoCopyToNas) {
  Write-Host "[$op] Mirroring to NAS: $NasPath" -ForegroundColor Cyan
  foreach ($row in $log) {
    $src = $row.Dest
    $nas = Ensure-DestDir -base $NasPath -f (Get-Item -LiteralPath $src)
    if ($DryRun) {
      Write-Host "? would copy: $src -> $nas" -ForegroundColor DarkGray
    } else {
      Copy-Item -LiteralPath $src -Destination $nas -Force
    }
  }
}

$outDir = Join-Path $PSScriptRoot "..\DATA\_work"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$csv = Join-Path $outDir ("transfer_log_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".csv")
$log | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csv
Write-Host "Log written: $csv" -ForegroundColor Green
