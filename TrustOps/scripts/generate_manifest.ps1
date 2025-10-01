<#!
Generate file manifest (PowerShell 5.1)

Outputs:
  - CSV + JSONL manifest with path, size, modified, SHA256

Usage:
  .\generate_manifest.ps1 -Root . -OutDir C:\ProgramData\TrustOps\Manifests
!#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)] [string]$Root,
  [string]$OutDir = 'C:\ProgramData\TrustOps\Manifests'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-Dirs([string]$p){ if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null } }

function Get-HashHex([string]$path){
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $fs = [System.IO.File]::OpenRead($path)
    try {
      $h = $sha.ComputeHash($fs)
      return ([System.BitConverter]::ToString($h)).Replace('-', '')
    } finally { $fs.Dispose() }
  } finally { $sha.Dispose() }
}

try {
  $rootPath = (Resolve-Path -LiteralPath $Root).Path
  New-Dirs $OutDir
  $stamp = (Get-Date -Format 'yyyyMMdd-HHmmss')
  $csv = Join-Path $OutDir ("manifest-$stamp.csv")
  $jsonl = Join-Path $OutDir ("manifest-$stamp.jsonl")
  $rows = @()
  $files = Get-ChildItem -LiteralPath $rootPath -File -Recurse -ErrorAction SilentlyContinue
  foreach ($f in $files) {
    $rows += [PSCustomObject]@{
      path = $f.FullName
      size = $f.Length
      modified = $f.LastWriteTimeUtc.ToString('s')
      sha256 = Get-HashHex $f.FullName
    }
  }
  $rows | Export-Csv -NoTypeInformation -Path $csv -Encoding UTF8
  $sw = New-Object System.IO.StreamWriter($jsonl, $false, (New-Object System.Text.UTF8Encoding($false)))
  try { foreach ($r in $rows) { $sw.WriteLine((ConvertTo-Json $r -Depth 4 -Compress)) } } finally { $sw.Dispose() }
  Write-Host "Manifest written: $csv | $jsonl"
} catch {
  Write-Error $_
  exit 1
}
