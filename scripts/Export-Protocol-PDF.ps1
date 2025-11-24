param(
    [Parameter(Mandatory=$true)][string]$InputPath,
    [Parameter(Mandatory=$true)][string]$OutputPath,
    [switch]$Open
)

$ErrorActionPreference = 'Stop'
function Fail($m){ Write-Error $m; exit 1 }

if (!(Test-Path -LiteralPath $InputPath)) { Fail "Input not found: $InputPath" }

$pandoc = Get-Command pandoc -ErrorAction SilentlyContinue
if (-not $pandoc) { Fail "pandoc not found. Install from https://pandoc.org/installing.html" }

$wkhtml = Get-Command wkhtmltopdf -ErrorAction SilentlyContinue
$xelatex = Get-Command xelatex -ErrorAction SilentlyContinue

# Ensure output directory exists
$outDir = Split-Path -Parent $OutputPath
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

# Common pandoc args
$args = @(
    '"' + $InputPath + '"',
    '-o', '"' + $OutputPath + '"'
)

if ($wkhtml) {
    $args += @(
        '--pdf-engine=wkhtmltopdf',
        '-V','margin-top=2.5cm','-V','margin-bottom=2.5cm','-V','margin-left=2.5cm','-V','margin-right=2.5cm',
        '-V','header-left=Sovereign Data Continuity Protocol v7.0',
        '-V','footer-left=Andy Jones – Confidential – 19 November 2025',
        '-V','footer-right=Page [page] of [toPage]'
    )
}
elseif ($xelatex) {
    $args += @(
        '--pdf-engine=xelatex',
        '-V','geometry:margin=2.5cm',
        '-V','mainfont=Arial',
        '-V','fontsize=12pt'
    )
}
else {
    Fail "No PDF engine found. Install wkhtmltopdf (https://wkhtmltopdf.org/) or a LaTeX engine (e.g., TinyTeX)."
}

Write-Host "[INFO] Exporting PDF via pandoc..." -ForegroundColor Cyan
$cmd = "$($pandoc.Source) $($args -join ' ')"
# Use cmd.exe to preserve quoted args reliably
cmd /c $cmd | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "pandoc failed with exit code $LASTEXITCODE" }

if (-not (Test-Path -LiteralPath $OutputPath)) { Fail "PDF not created: $OutputPath" }

Write-Host "[OK] PDF written: $OutputPath" -ForegroundColor Green
if ($Open) { Start-Process -FilePath $OutputPath }
