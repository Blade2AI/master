[CmdletBinding()]
param(
  [switch]$SkipMedia,
  [switch]$SkipPolicy,
  [switch]$SkipHealth,
  [switch]$SkipDryRun,
  [switch]$AutoMerge,
  [string]$VideoInput = '',
  [string]$VideoList = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Step($name, [scriptblock]$code){
  Write-Host "=== $name ===" -ForegroundColor Cyan
  try { & $code; Write-Host "[OK] $name" -ForegroundColor Green }
  catch { Write-Host "[FAIL] $name :: $($_.Exception.Message)" -ForegroundColor Red; throw }
}

$ws = Split-Path -Parent $PSScriptRoot

# 0 Preflight
Step 'Preflight' { powershell -NoProfile -ExecutionPolicy Bypass -File "C:/Users/andyj/AI_Agent_Research/sovereign_ide_preflight.ps1" }

if(-not $SkipMedia){
  if($VideoInput){ Step 'Transcribe Video' { powershell -NoProfile -ExecutionPolicy Bypass -File "$ws/scripts/Transcribe-Video.ps1" -Input $VideoInput -SplitParts 2 -ContinueOnError } }
  if($VideoList){ Step 'Merge Transcripts' { powershell -NoProfile -ExecutionPolicy Bypass -File "$ws/scripts/G-Transcript.ps1" -Inputs $VideoList -SplitParts 2 -EmitIndexJson -ContinueOnError } }
}

if(-not $SkipPolicy){
  Step 'Policy Validate' { powershell -NoProfile -ExecutionPolicy Bypass -File "$ws/scripts/Validate-Policy.ps1" }
  Step 'Policy Sign' { powershell -NoProfile -ExecutionPolicy Bypass -File "$ws/scripts/Sign-Policies.ps1" }
}

if(-not $SkipHealth){
  Step 'Healthcheck' { powershell -NoProfile -ExecutionPolicy Bypass -File "$ws/scripts/Healthcheck.ps1" }
  Step 'Ledger Audit' { powershell -NoProfile -ExecutionPolicy Bypass -File "$ws/scripts/Ledger-Audit.ps1" }
}

if(-not $SkipDryRun){
  Step 'Close-out Dry Run' { powershell -NoProfile -ExecutionPolicy Bypass -File "$ws/scripts/master_closeout.ps1" -WorkspacePath $ws -DryRun }
}

Write-Host "Dry run completed. Resolve issues before final auditable close-out." -ForegroundColor Yellow
if($AutoMerge){
  Write-Host "AutoMerge flag set: performing Auditable close-out..." -ForegroundColor Cyan
  Step 'Close-out Auditable' { powershell -NoProfile -ExecutionPolicy Bypass -File "$ws/scripts/master_closeout.ps1" -WorkspacePath $ws }
  Step 'SITREP' { powershell -NoProfile -ExecutionPolicy Bypass -File "$ws/Get-ProjectSITREP.ps1" -ProjectsRoot "Z:/Forge/apps" -OutputFile "$ws/PROJECT_SITREP.md" }
  Step 'Commit Push' { powershell -NoProfile -ExecutionPolicy Bypass -File "$ws/scripts/End-Collab.ps1" -WorkspacePath $ws -Message "Automated pipeline completion" }
}
