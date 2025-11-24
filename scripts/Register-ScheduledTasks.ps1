<#!
.SYNOPSIS
  Register a Windows Scheduled Task to run the Flight Recorder sealing script daily.
.DESCRIPTION
  Proof mode: run as current user. Optional SYSTEM principal for hardened runs.
  Never stores secrets; relies on environment variables / external secure storage.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$TaskName = 'SovereignFlightRecorder-Daily',
  [string]$RepoRoot = 'C:\Users\andyj\source\repos\PrecisePointway\master',
  [string]$LedgerRelativePath = 'docs\audit\ledger_snapshot.json',
  [ValidateSet('dev','staging','prod','proof')][string]$Environment='proof',
  [switch]$RunAsSystem
)
$ErrorActionPreference='Stop'

$scriptPath = Join-Path $RepoRoot 'scripts\Seal-And-Anchor-Dual.ps1'
$ledgerPath = Join-Path $RepoRoot $LedgerRelativePath
$outDir     = Join-Path $RepoRoot 'out\anchors'
$schemaPath = Join-Path $RepoRoot 'schemas\event_anchor.json'

if(-not (Test-Path $scriptPath)){ throw "Seal-And-Anchor-Dual.ps1 not found: $scriptPath" }
if(-not (Test-Path $outDir)){ New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
if(-not (Test-Path $ledgerPath)){ Write-Host "[WARN] Ledger snapshot missing: $ledgerPath" -ForegroundColor Yellow }
if(-not (Test-Path $schemaPath)){ Write-Host "[WARN] Schema missing: $schemaPath" -ForegroundColor Yellow }

$arguments = @(
  '-NoLogo','-NonInteractive','-File',"`"$scriptPath`"",
  '-LedgerPath',"`"$ledgerPath`"",
  '-OutputDir',"`"$outDir`"",
  '-SchemaPath',"`"$schemaPath`"",
  '-Environment',"`"$Environment`""
) -join ' '

$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument $arguments -WorkingDirectory $RepoRoot
$trigger = New-ScheduledTaskTrigger -Daily -At 02:15
if($RunAsSystem){
  $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
} else {
  $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType InteractiveToken -RunLevel Highest
}
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Description 'Sovereign Flight Recorder daily sealing + anchor (GDPR-safe).'
if($PSCmdlet.ShouldProcess($TaskName,'Register-ScheduledTask')){
  Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force
  Write-Host "[OK] Scheduled task registered: $TaskName (Environment=$Environment System=$RunAsSystem)" -ForegroundColor Green
  Write-Host "Document in DPIA before production hardening." -ForegroundColor Cyan
}
