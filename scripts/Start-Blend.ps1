param(
    [Parameter(Mandatory=$true)][string]$Path,
    [switch]$Wait
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-BlendPath {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (Test-Path -LiteralPath $vswhere) {
        $instPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath 2>$null
        if ($LASTEXITCODE -eq 0 -and $instPath) {
            $candidates = @(
                (Join-Path $instPath 'Common7/IDE/Blend/Blend.exe'),
                (Join-Path $instPath 'Common7/IDE/Blend.exe')
            )
            foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return $c } }
        }
    }
    $fallbacks = @(
        'C:/Program Files/Microsoft Visual Studio/2022/Community/Common7/IDE/Blend/Blend.exe',
        'C:/Program Files/Microsoft Visual Studio/2022/Professional/Common7/IDE/Blend/Blend.exe',
        'C:/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/IDE/Blend/Blend.exe'
    )
    foreach ($f in $fallbacks) { if (Test-Path -LiteralPath $f) { return $f } }
    throw 'Blend.exe not found. Ensure Blend for Visual Studio is installed.'
}

if (-not (Test-Path -LiteralPath $Path)) { throw "Target not found: $Path" }
$blend = Get-BlendPath

Write-Host "[INFO] Launching Blend: $Path" -ForegroundColor Cyan
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $blend
$psi.Arguments = '"' + (Resolve-Path -LiteralPath $Path) + '"'
$psi.UseShellExecute = $true
$proc = [System.Diagnostics.Process]::Start($psi)
if ($Wait) { $proc.WaitForExit() }
