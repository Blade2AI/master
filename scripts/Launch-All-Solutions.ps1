param(
    [Parameter(Mandatory=$true)][string[]]$SolutionPaths,
    [switch]$Wait
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$launched = @()
foreach ($sln in $SolutionPaths) {
    if (-not (Test-Path -LiteralPath $sln)) {
        Write-Warning "Skipping missing: $sln"
        continue
    }
    & $PSScriptRoot/Start-VisualStudio.ps1 -Path $sln -Wait:$Wait
    $launched += $sln
}

if ($launched.Count -gt 0) {
    Write-Host "[INFO] Launched $($launched.Count) solution(s)." -ForegroundColor Green
} else {
    Write-Host "[WARN] No solutions launched. Check paths." -ForegroundColor Yellow
}
