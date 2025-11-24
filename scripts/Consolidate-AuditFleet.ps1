<#
.SYNOPSIS
  Sovereign Fleet Auditor - Consolidation Script.
  Merges audit exports from multiple nodes into unified historical IP ledger and deletion proposal.
.DESCRIPTION
  Expects per-node CSVs matching patterns:
    *_DEEP_FORGE.csv   (file inventory: Path, SizeBytes/SizeKB, LastModified)
    *_AI_MODELS.csv    (model inventory: Path or ModelPath, SizeBytes/SizeMB, LastModified)
  Adds classification:
    Canonical        -> file within governed repos root
    Rogue            -> outside canonical roots
    DeclaredLocation -> model under expected model directories
    Anomalous        -> large model outside declared directories
.NOTES
  Adjust DeclaredModelDirs / LargeModelMinMB as environment changes.
#>
param(
  [Parameter(Mandatory=$true)][string[]]$AuditRoots,
  [string]$CanonicalReposRoot = 'C:\Users\andyj\source\repos',
  [string]$OutDir = './FINAL_LEDGER_OUTPUT',
  [string]$CanonicalLedger = 'Fleet_HistoricalIP_Ledger.csv',
  [string]$DeletionList = 'Fleet_ColdStorage_Delete.csv',
  [int]$LargeModelMinMB = 50,
  [string[]]$DeclaredModelDirs = @("$env:USERPROFILE/.lmstudio/models","C:\Models","C:\AI\Models","D:\LLM")
)
function Ensure-Dir($p){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Load-CsvSingle([string]$root,[string]$pattern){ Get-ChildItem -Path $root -Filter $pattern -ErrorAction SilentlyContinue | Select-Object -First 1 }

Ensure-Dir $OutDir
$deepRows = @(); $modelRows = @()
Write-Host '--- Consolidation Start ---' -ForegroundColor Cyan
Write-Host "Canonical Root: $CanonicalReposRoot" -ForegroundColor Gray
Write-Host "Audit Roots: $($AuditRoots -join ', ')" -ForegroundColor Gray

foreach($root in $AuditRoots){
  if(-not (Test-Path $root)){ Write-Warning "Missing audit root: $root"; continue }
  $nodeName = (Split-Path $root -Leaf) -replace '^_AUDIT_RESULTS_','' -replace '_\d{8}_\d{6}$',''
  Write-Host "Processing node: $nodeName" -ForegroundColor DarkGray

  $deepCsv   = Load-CsvSingle $root '*_DEEP_FORGE.csv'
  $modelsCsv = Load-CsvSingle $root '*_AI_MODELS.csv'

  if($deepCsv){
    try { (Import-Csv -LiteralPath $deepCsv.FullName) | ForEach-Object { $_ | Add-Member Node $nodeName -Force; $deepRows += $_ } } catch { Write-Warning "Failed import deep forge: $($_.Exception.Message)" }
  } else { Write-Warning "No DEEP_FORGE for $root" }
  if($modelsCsv){
    try {
      (Import-Csv -LiteralPath $modelsCsv.FullName) | ForEach-Object {
        $_ | Add-Member Node $nodeName -Force
        if(-not $_.PSObject.Properties['ModelPath']){ $_ | Add-Member ModelPath $_.Path -Force }
        $modelRows += $_
      }
    } catch { Write-Warning "Failed import AI models: $($_.Exception.Message)" }
  } else { Write-Warning "No AI_MODELS for $root" }
}
Write-Host "Deep Forge rows: $($deepRows.Count)" -ForegroundColor Green
Write-Host "Model rows: $($modelRows.Count)" -ForegroundColor Green

# Canonical repository roots
$canonicalRoots = @()
if(Test-Path $CanonicalReposRoot){ $canonicalRoots = Get-ChildItem -Path $CanonicalReposRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName } }

# Tag canonical/rogue
$deepRows | ForEach-Object {
  $p=$_.Path; $isCanon=$false
  foreach($cr in $canonicalRoots){ if($p -like "$cr*"){ $isCanon=$true; break } }
  $_ | Add-Member Canonical $isCanon -Force
  $_ | Add-Member Rogue (-not $isCanon) -Force
}
$rogue = $deepRows | Where-Object Rogue
Write-Host "Rogue development files: $($rogue.Count)" -ForegroundColor Yellow

# Tag models declared/anomalous
$modelRows | ForEach-Object {
  $mp=$_.ModelPath; $declared=$false
  foreach($dDir in $DeclaredModelDirs){ if($dDir -and (Test-Path $dDir) -and ($mp -like "$dDir*")){ $declared=$true; break } }
  $sizeMB = if($_.PSObject.Properties['SizeBytes']){ [math]::Round(($_.SizeBytes/1MB),2) } elseif($_.PSObject.Properties['SizeMB']){ [double]$_.SizeMB } else { 0 }
  $anomalous = (-not $declared) -and ($sizeMB -ge $LargeModelMinMB)
  $_ | Add-Member DeclaredLocation $declared -Force
  $_ | Add-Member SizeMB $sizeMB -Force
  $_ | Add-Member Anomalous $anomalous -Force
}
$anomalousModels = $modelRows | Where-Object Anomalous
Write-Host "Anomalous models (>=$LargeModelMinMB MB outside declared dirs): $($anomalousModels.Count)" -ForegroundColor Yellow

# Build ledger (normalize size and timestamp fields)
$ledger = $deepRows | Select-Object Node, Path, @{n='SizeKB';e={ if($_.PSObject.Properties['SizeKB']){ $_.SizeKB } elseif($_.PSObject.Properties['SizeBytes']){ [math]::Round($_.SizeBytes/1KB,2) } else { '' } }}, @{n='LastModified';e={ if($_.PSObject.Properties['LastModified']){ $_.LastModified } elseif($_.PSObject.Properties['ModifiedUtc']){ $_.ModifiedUtc } else { '' } }}, Canonical
$ledgerPath = Join-Path $OutDir $CanonicalLedger
$ledger | Export-Csv -LiteralPath $ledgerPath -NoTypeInformation -Encoding UTF8

# Deletion proposal (rogue files + anomalous models)
$deleteList = @()
$deleteList += ($rogue | Select-Object Node, Path, @{n='SizeKB';e={ if($_.PSObject.Properties['SizeKB']){ $_.SizeKB } elseif($_.PSObject.Properties['SizeBytes']){ [math]::Round($_.SizeBytes/1KB,2) } else { '' } }}, @{n='LastModified';e={ if($_.PSObject.Properties['LastModified']){ $_.LastModified } elseif($_.PSObject.Properties['ModifiedUtc']){ $_.ModifiedUtc } else { '' } }}, @{n='Reason';e={'Rogue Development File'}})
$deleteList += ($anomalousModels | Select-Object Node, @{n='Path';e={$_.ModelPath}}, SizeMB, @{n='LastModified';e={ if($_.PSObject.Properties['LastModified']){ $_.LastModified } elseif($_.PSObject.Properties['ModifiedUtc']){ $_.ModifiedUtc } else { '' } }}, @{n='Reason';e={'Anomalous Model (Outside Declared Dirs)'}})
$deletePath = Join-Path $OutDir $DeletionList
$deleteList | Export-Csv -LiteralPath $deletePath -NoTypeInformation -Encoding UTF8

Write-Host '--- Consolidation Complete ---' -ForegroundColor Green
Write-Host "Ledger: $ledgerPath" -ForegroundColor Green
Write-Host "Deletion Proposal: $deletePath" -ForegroundColor Yellow
Write-Host "Rogue Files: $($rogue.Count) | Anomalous Models: $($anomalousModels.Count)" -ForegroundColor Gray
