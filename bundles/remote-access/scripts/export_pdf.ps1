param(
  [Parameter(Mandatory=$true)][string]$InputHtml,
  [Parameter(Mandatory=$true)][string]$OutputPdf,
  [switch]$Landscape
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-BrowserPath {
  $candidates = @(
    "$Env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe",
    "$Env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "$Env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe",
    "$Env:ProgramFiles\Google\Chrome\Application\chrome.exe"
  )
  foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
  throw "Edge/Chrome not found. Install Microsoft Edge or Google Chrome."
}

function Resolve-PathStrict([string]$p) {
  $fp = Resolve-Path -LiteralPath $p -ErrorAction Stop
  return $fp.Path
}

$inPath = Resolve-PathStrict $InputHtml
$outDir = Split-Path -Parent $OutputPdf
if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
$outPath = Join-Path $outDir (Split-Path -Leaf $OutputPdf)

$browser = Get-BrowserPath

$browserArgs = @(
  "--headless=new",
  "--disable-gpu",
  "--print-to-pdf=$outPath"
)
if ($Landscape) { $browserArgs += "--print-to-pdf-no-header"; $browserArgs += "--virtual-time-budget=30000" }
$browserArgs += $inPath

Write-Host "Rendering PDF via $browser" -ForegroundColor Cyan
& $browser $browserArgs

if (-not (Test-Path -LiteralPath $outPath)) { throw "PDF not created: $outPath" }
Write-Host "PDF created: $outPath" -ForegroundColor Green
