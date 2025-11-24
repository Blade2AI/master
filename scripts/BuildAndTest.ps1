[CmdletBinding()]
param(
  [switch]$Release
)

Write-Host "[BuildAndTest] Starting build sequence" -ForegroundColor Cyan
if(-not $env:LIBSODIUM_ROOT){
  $default = Join-Path $PSScriptRoot "..\deps\libsodium\libsodium"
  if(Test-Path $default){ $env:LIBSODIUM_ROOT = $default }
}
Write-Host "[BuildAndTest] LIBSODIUM_ROOT=$env:LIBSODIUM_ROOT" -ForegroundColor Gray

$verifierPath = Join-Path $PSScriptRoot "..\src\verifier"
Set-Location $verifierPath
if(Test-Path build){ Remove-Item build -Recurse -Force }

$cfg = if($Release){'Release'} else {'Debug'}
cmake -S . -B build | Out-Host
cmake --build build --config $cfg | Out-Host

$testExe = Join-Path $verifierPath "build\$cfg\verify_evidence_tests.exe"
if(Test-Path $testExe){
  Write-Host "[BuildAndTest] Running tests ($cfg)" -ForegroundColor Cyan
  & $testExe | Out-Host
}else{
  Write-Warning "Test executable not found: $testExe"
}
