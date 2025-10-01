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

$in = Resolve-PathStrict $InputHtml
$out = Resolve-Path -LiteralPath (Split-Path -Parent $OutputPdf) -ErrorAction SilentlyContinue
if (-not $out) { New-Item -ItemType Directory -Path (Split-Path -Parent $OutputPdf) -Force | Out-Null }
$out = (Resolve-Path -LiteralPath (Split-Path -Parent $OutputPdf)).Path + \\ + (Split-Path -Leaf $OutputPdf)

$browser = Get-BrowserPath

$args = @(
  "--headless=new",
  "--disable-gpu",
  "--print-to-pdf=$out"
)
if ($Landscape) { $args += "--print-to-pdf-no-header"; $args += "--virtual-time-budget=30000" }
$args += $in

Write-Host "Rendering PDF via $browser" -ForegroundColor Cyan
& $browser $args

if (-not (Test-Path $out)) { throw "PDF not created: $out" }
Write-Host "PDF created: $out" -ForegroundColor Green
