<#!
.SYNOPSIS
  Collect per-node DEEP_FORGE / AI_MODELS CSVs and run Consolidate-AuditFleet.ps1.
.DESCRIPTION
  Attempts UNC copy from each node's C$ share path convention:
    C:\SovereignAudit\<Node>_DEEP_FORGE.csv
    C:\SovereignAudit\<Node>_AI_MODELS.csv
  Then consolidates into fleet outputs.
#>
[CmdletBinding()]
param(
  [string[]]$Nodes = @('PC1','PC2','PC3','PC4','PC5','NAS'),
  [string]$LocalFleetRoot = 'C:\SovereignAudit\Fleet',
  [string]$CanonicalReposRoot = 'C:\Users\andyj\source\repos',
  [string]$ConsolidatorPath = (Join-Path $PSScriptRoot 'Consolidate-AuditFleet.ps1')
)
$ErrorActionPreference='Stop'
Write-Host '=== RUN Fleet Audit + Consolidation ===' -ForegroundColor Cyan
Write-Host "Nodes: $($Nodes -join ', ')" -ForegroundColor Cyan
if(-not (Test-Path $LocalFleetRoot)){ New-Item -ItemType Directory -Force -Path $LocalFleetRoot | Out-Null }
$nodeDirs=@()
foreach($node in $Nodes){
  $nodeDir = Join-Path $LocalFleetRoot $node
  New-Item -ItemType Directory -Force -Path $nodeDir | Out-Null
  $remoteBase = "\\$node\C$\SovereignAudit"
  $deepForge  = Join-Path $remoteBase ("${node}_DEEP_FORGE.csv")
  $aiModels   = Join-Path $remoteBase ("${node}_AI_MODELS.csv")
  Write-Host "Node $node:" -ForegroundColor White
  if(Test-Path $deepForge){ Copy-Item $deepForge -Destination (Join-Path $nodeDir (Split-Path $deepForge -Leaf)) -Force; Write-Host '  + DEEP_FORGE copied' -ForegroundColor Green } else { Write-Host '  ! Missing DEEP_FORGE' -ForegroundColor Yellow }
  if(Test-Path $aiModels){ Copy-Item $aiModels -Destination (Join-Path $nodeDir (Split-Path $aiModels -Leaf)) -Force; Write-Host '  + AI_MODELS copied' -ForegroundColor Green } else { Write-Host '  ! Missing AI_MODELS' -ForegroundColor Yellow }
  $hasFiles = Get-ChildItem $nodeDir -Filter '*_DEEP_FORGE.csv' -ErrorAction SilentlyContinue
  if($hasFiles){ $nodeDirs += $nodeDir }
}
if(-not (Test-Path $ConsolidatorPath)){ throw "Consolidate-AuditFleet.ps1 not found: $ConsolidatorPath" }
$OutDir = Join-Path $LocalFleetRoot 'out'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Write-Host 'Running Consolidate-AuditFleet.ps1...' -ForegroundColor Cyan
pwsh -File $ConsolidatorPath -AuditRoots $nodeDirs -CanonicalReposRoot $CanonicalReposRoot -OutDir $OutDir
$ledgerPath = Join-Path $OutDir 'Fleet_HistoricalIP_Ledger.csv'
$deletePath = Join-Path $OutDir 'Fleet_ColdStorage_Delete.csv'
Write-Host '=== Fleet outputs ===' -ForegroundColor Cyan
if(Test-Path $ledgerPath){ $lines=(Get-Content $ledgerPath).Count; Write-Host "Ledger: $ledgerPath ($lines lines)" -ForegroundColor Green } else { Write-Host 'Ledger missing' -ForegroundColor Red }
if(Test-Path $deletePath){ $lines=(Get-Content $deletePath).Count; Write-Host "Delete list: $deletePath ($lines lines)" -ForegroundColor Green } else { Write-Host 'Delete list missing' -ForegroundColor Red }
Write-Host 'Next: upload both CSVs for compliance diff.' -ForegroundColor Cyan
