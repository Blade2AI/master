param(
  [string]$OutDir = "artifacts/evidence_pack",
  [int]$GitLogLines = 200,
  [switch]$IncludeAllFiles,
  [switch]$Quiet
)
$ErrorActionPreference = 'Stop'
function Log($m){ if(-not $Quiet){ Write-Host "[EVIDENCE] $m" -ForegroundColor Cyan } }

# Resolve repo root (parent of scripts directory)
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..') | Select-Object -ExpandProperty Path
$OutDirFull = Join-Path $RepoRoot $OutDir
if(-not (Test-Path $OutDirFull)){ New-Item -ItemType Directory -Force -Path $OutDirFull | Out-Null }

Log "RepoRoot: $RepoRoot"
Log "OutDir: $OutDirFull"

# 1. Git log
$git = Get-Command git -ErrorAction SilentlyContinue
if($git){
  try {
    $logText = & $git.Path -C $RepoRoot log --oneline -n $GitLogLines 2>&1
    $logFile = Join-Path $OutDirFull 'git_log.txt'
    $logText | Out-File -LiteralPath $logFile -Encoding UTF8
    Log "Wrote git log ($GitLogLines lines)."
  } catch { Log "Git log capture failed: $_" }
} else { Log "Git not found – skipping git log." }

# 2. Repository tree (depth-limited)
function Get-RepoTree {
  param([string]$Root)
  $exclude = @('.git','artifacts','node_modules','__pycache__','.venv','.mypy_cache')
  Get-ChildItem -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
    foreach($ex in $exclude){ if($_.FullName -like "*\$ex*"){ return $false } }; return $true
  } | ForEach-Object {
    $relative = (Resolve-Path $_.FullName).Path.Substring($Root.Length).TrimStart('\\')
    if($relative){ $relative }
  }
}
$treeFile = Join-Path $OutDirFull 'tree.txt'
Get-RepoTree -Root $RepoRoot | Sort-Object | Out-File -LiteralPath $treeFile -Encoding UTF8
Log "Wrote repository tree."\n
# 3. Hash manifest
$manifest = [ordered]@{ generated_utc=(Get-Date).ToUniversalTime().ToString('o'); root_sha256=$null; files=@() }
$targets = if($IncludeAllFiles){ Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -ErrorAction SilentlyContinue } else {
  $patterns = @('scripts','src','docs','schemas','config')
  Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match "\\($([string]::Join('|',$patterns)))\\" }
}
foreach($f in $targets){
  try {
    $h = Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256
    $rel = $f.FullName.Substring($RepoRoot.Length).TrimStart('\\')
    $manifest.files += [ordered]@{ path=$rel; sha256=$h.Hash.ToLower(); size=$f.Length }
  } catch {}
}
# Deterministic root (Merkle-style: hash of concatenated file hashes sorted by path)
$ordered = $manifest.files | Sort-Object path
$concat = ($ordered | ForEach-Object { $_.sha256 }) -join ''
$rootBytes = [Text.Encoding]::UTF8.GetBytes($concat)
$rootHash = (Get-FileHash -InputStream ([IO.MemoryStream]::new($rootBytes)) -Algorithm SHA256).Hash.ToLower()
$manifest.root_sha256 = $rootHash
$manifestFile = Join-Path $OutDirFull 'hash_manifest.json'
$manifest | ConvertTo-Json -Depth 4 | Out-File -LiteralPath $manifestFile -Encoding UTF8
Log "Wrote hash manifest (files=$($manifest.files.Count)). Root=$rootHash"

# 4. Sample heartbeat placeholder (if schema exists)
$heartbeatSchema = Join-Path $RepoRoot 'schemas/event_heartbeat.json'
if(Test-Path $heartbeatSchema){
  $sampleHeartbeat = [ordered]@{
    event_type = 'heartbeat'
    node = $env:COMPUTERNAME
    timestamp = (Get-Date).ToUniversalTime().ToString('o')
    merkle_root = $rootHash
    version = '0.1'
  }
  $hbFile = Join-Path $OutDirFull 'heartbeat_sample.json'
  $sampleHeartbeat | ConvertTo-Json -Depth 3 | Out-File -LiteralPath $hbFile -Encoding UTF8
  Log "Wrote heartbeat_sample.json"
} else { Log "Heartbeat schema missing – skipped sample heartbeat." }

# 5. Evidence summary
$summary = [ordered]@{
  generated_utc = (Get-Date).ToUniversalTime().ToString('o')
  repo_root = $RepoRoot
  git_log = (Test-Path $logFile)
  tree = (Test-Path $treeFile)
  hash_manifest = (Test-Path $manifestFile)
  heartbeat_sample = (Test-Path (Join-Path $OutDirFull 'heartbeat_sample.json'))
  file_count = $manifest.files.Count
  root_sha256 = $manifest.root_sha256
}
$summaryFile = Join-Path $OutDirFull 'evidence_summary.json'
$summary | ConvertTo-Json -Depth 3 | Out-File -LiteralPath $summaryFile -Encoding UTF8
Log "Wrote evidence_summary.json"

# 6. Zip pack
$zipPath = Join-Path $OutDirFull 'evidence_pack.zip'
if(Test-Path $zipPath){ Remove-Item -LiteralPath $zipPath -Force }
Compress-Archive -LiteralPath (Get-ChildItem -LiteralPath $OutDirFull -File | ForEach-Object { $_.FullName }) -DestinationPath $zipPath -Force
Log "Compressed evidence_pack.zip"

Log "Evidence pack generation complete."