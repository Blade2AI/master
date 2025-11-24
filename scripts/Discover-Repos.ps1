[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$ManifestFile,
  [switch]$IncludeNested
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err ($m){ Write-Host "[FAIL] $m" -ForegroundColor Red }

if (-not (Test-Path -LiteralPath $Root)) { throw "Root not found: $Root" }
if (-not (Test-Path -LiteralPath $ManifestFile)) { New-Item -ItemType File -Path $ManifestFile -Force | Out-Null }

# Load existing URLs from manifest for dedupe
$existing = @{}
Get-Content -LiteralPath $ManifestFile | ForEach-Object {
  $raw = $_.Trim()
  if ($raw -and -not $raw.StartsWith('#')) {
    $parts = $raw -split '\s+'
    if ($parts.Length -ge 1) { $existing[$parts[0]] = $true }
  }
}

# Enumerate candidate repo roots
$dirs = if ($IncludeNested) {
  Get-ChildItem -LiteralPath $Root -Recurse -Directory -Force -ErrorAction SilentlyContinue
} else {
  Get-ChildItem -LiteralPath $Root -Directory -Force -ErrorAction SilentlyContinue
}

$newLines = @()
foreach ($d in $dirs) {
  try {
    $gitDir = Join-Path $d.FullName '.git'
    if (-not (Test-Path -LiteralPath (Join-Path $gitDir 'config'))) { continue }

    # Try to read remote.origin.url
    $url = $null
    try {
      $url = & git -C $d.FullName remote get-url origin 2>$null
    } catch { $url = $null }
    if (-not $url) {
      $match = Select-String -Path (Join-Path $gitDir 'config') -Pattern 'url\s*=\s*(.+)' -List -ErrorAction SilentlyContinue
      if ($match) { $url = $match.Matches[0].Groups[1].Value.Trim() }
    }
    if (-not $url) { continue }

    if (-not $existing.ContainsKey($url)) {
      $line = "$url $($d.Name)"
      $newLines += $line
      $existing[$url] = $true
    }
  } catch {
    Write-Warn "Skip $($d.FullName): $($_.Exception.Message)"
  }
}

if ($newLines.Count -gt 0) {
  Write-Info "Appending $($newLines.Count) repo(s) to manifest: $ManifestFile"
  Add-Content -LiteralPath $ManifestFile -Value ("# Auto-discovered $(Get-Date -Format o)")
  $newLines | Add-Content -LiteralPath $ManifestFile
  $newLines | ForEach-Object { Write-Host "  + $_" }
} else {
  Write-Info "No new repositories discovered under $Root"
}
