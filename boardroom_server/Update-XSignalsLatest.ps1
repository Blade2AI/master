<#!
Copy latest X signals CSV to Boardroom alias path: DATA/_results/x_signals_latest.csv

Search order:
 - ProgramData\TrustOps\Signals
 - TrustOps\DATA\_results
 - boardroom_server\DATA\_results

Usage:
  .\Update-XSignalsLatest.ps1 -SourceDir "C:\ProgramData\TrustOps\Signals"
!#>

[CmdletBinding()]
param(
  [string]$SourceDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Find-Candidate([string]$dir){
  if (-not $dir) { return $null }
  if (-not (Test-Path -LiteralPath $dir)) { return $null }
  $c = Get-ChildItem -LiteralPath $dir -Filter '*x_signals*.csv' -File -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  return $c
}

try {
  $root = Split-Path -Parent $PSScriptRoot
  $aliasDir = Join-Path $root 'wwwroot\DATA\_results'
  if (-not (Test-Path -LiteralPath $aliasDir)) { New-Item -ItemType Directory -Path $aliasDir -Force | Out-Null }

  $candidates = @()
  if ($SourceDir) { $candidates += Find-Candidate $SourceDir }
  $candidates += Find-Candidate 'C:\ProgramData\TrustOps\Signals'
  $candidates += Find-Candidate (Join-Path $root 'DATA\_results')
  $candidates += Find-Candidate (Join-Path (Split-Path -Parent $root) 'TrustOps\DATA\_results')
  $cand = $candidates | Where-Object { $_ } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $cand) { Write-Host 'No x_signals CSV found.'; exit 0 }

  $dest = Join-Path $aliasDir 'x_signals_latest.csv'
  Copy-Item -LiteralPath $cand.FullName -Destination $dest -Force
  Write-Host ("Updated alias: {0} -> {1}" -f $cand.FullName, $dest)
} catch {
  Write-Error $_
  exit 1
}
