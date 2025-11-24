<#!
.SYNOPSIS
  Aggregate harness for recorder validation.
.DESCRIPTION
  Invokes Test-RecorderEvents.ps1. Extend later with additional integrity checks.
#>
[CmdletBinding()]param(
  [string]$EventsRoot='data/recorder/events',
  [string]$PythonExe='python'
)
$ErrorActionPreference='Stop'
Write-Host '== Recorder Validation Harness ==' -ForegroundColor Cyan
$testScript='scripts/Test-RecorderEvents.ps1'
if(-not (Test-Path $testScript)){ throw "Test script missing: $testScript" }

pwsh -File $testScript -EventsRoot $EventsRoot -PythonExe $PythonExe
if($LASTEXITCODE -ne 0){ Write-Host 'Recorder validation FAILED.' -ForegroundColor Red; exit $LASTEXITCODE }
Write-Host 'Recorder validation PASSED.' -ForegroundColor Green
exit 0
