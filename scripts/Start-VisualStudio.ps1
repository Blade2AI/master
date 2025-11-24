param(
    [Parameter(Mandatory=$true)][string]$Path,
    [switch]$Wait
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-DevenvPath {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (Test-Path -LiteralPath $vswhere) {
        $instPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath 2>$null
        if ($LASTEXITCODE -eq 0 -and $instPath) {
            $devenv = Join-Path $instPath 'Common7/IDE/devenv.exe'
            if (Test-Path -LiteralPath $devenv) { return $devenv }
        }
    }
    $candidates = @(
        'C:/Program Files/Microsoft Visual Studio/2022/Community/Common7/IDE/devenv.exe',
        'C:/Program Files/Microsoft Visual Studio/2022/Professional/Common7/IDE/devenv.exe',
        'C:/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/IDE/devenv.exe'
    )
    foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return $c } }
    throw 'Visual Studio (devenv.exe) not found. Install VS 2022 or adjust script.'
}

$devenv = Get-DevenvPath
if (-not (Test-Path -LiteralPath $Path)) {
    throw "Target not found: $Path"
}

Write-Host "[INFO] Launching Visual Studio: $Path" -ForegroundColor Cyan
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $devenv
$psi.Arguments = '"' + $Path + '"'
$psi.UseShellExecute = $true
$proc = [System.Diagnostics.Process]::Start($psi)
if ($Wait) { $proc.WaitForExit() }
