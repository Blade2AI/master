param(
  [Parameter(Mandatory=$true)][string]$LedgerPath,          # Path to Fleet_HistoricalIP_Ledger.csv
  [Parameter(Mandatory=$true)][string]$DeletePath,          # Path to Fleet_ColdStorage_Delete.csv
  [string]$OutDir = (Split-Path $LedgerPath -Parent),       # Output directory (defaults to ledger directory)
  [string]$CleanName = "Fleet_HistoricalIP_Ledger_CLEAN.csv",
  [switch]$EmitSummaryJson,                                 # Also emit JSON summary file
  [string]$SummaryJsonName = "Fleet_HistoricalIP_Ledger_CLEAN.summary.json"
)

$ErrorActionPreference = 'Continue'

function Fail($m){ Write-Error $m; exit 1 }
function Ensure-Dir($p){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }

if(-not (Test-Path $LedgerPath)){ Fail "Ledger not found: $LedgerPath" }
if(-not (Test-Path $DeletePath)){ Fail "Delete list not found: $DeletePath" }

Ensure-Dir $OutDir

Write-Host "[Finalize] Loading ledger: $LedgerPath" -ForegroundColor Cyan
$ledger = Import-Csv -LiteralPath $LedgerPath
Write-Host "[Finalize] Loading deletion list: $DeletePath" -ForegroundColor Cyan
$delete = Import-Csv -LiteralPath $DeletePath

if(-not $ledger){ Fail "Ledger empty." }
if(-not $delete){ Fail "Deletion list empty." }

# Extract deletion paths (normalize case)
$delPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach($d in $delete){ if($d.Path){ [void]$delPaths.Add($d.Path) } }

Write-Host "[Finalize] Ledger rows: $($ledger.Count)" -ForegroundColor Gray
Write-Host "[Finalize] Delete paths: $($delPaths.Count)" -ForegroundColor Gray

# Remove rows whose Path is in deletion set (assume ledger has Path column)
$removed = @()
$clean = @()
foreach($row in $ledger){
  # Attempt to get Path; ledger may have column named 'Path' already
  $path = $row.Path
  if($path -and $delPaths.Contains($path)){
    $removed += $row
  } else {
    $clean += $row
  }
}

$cleanPath = Join-Path $OutDir $CleanName
$clean | Export-Csv -LiteralPath $cleanPath -NoTypeInformation -Encoding UTF8

Write-Host "[Finalize] Clean ledger written: $cleanPath" -ForegroundColor Green
Write-Host "[Finalize] Rows kept: $($clean.Count) | Rows removed: $($removed.Count)" -ForegroundColor Yellow

# Emit summary JSON optionally
if($EmitSummaryJson){
  $summary = [pscustomobject]@{
    timestamp = (Get-Date).ToString('o')
    input_ledger = (Resolve-Path $LedgerPath).Path
    input_deletions = (Resolve-Path $DeletePath).Path
    rows_original = $ledger.Count
    rows_removed = $removed.Count
    rows_clean = $clean.Count
    percent_removed = if($ledger.Count -gt 0){ [math]::Round(($removed.Count / $ledger.Count)*100,2) } else { 0 }
    deletion_paths = $delPaths
  }
  $summaryPath = Join-Path $OutDir $SummaryJsonName
  $summary | ConvertTo-Json -Depth 4 | Out-File -LiteralPath $summaryPath -Encoding UTF8
  Write-Host "[Finalize] Summary JSON written: $summaryPath" -ForegroundColor Green
}

# Optional: show top rogue reasons removed if Reason column present
$reasonCounts = @()
if($removed.Count -gt 0 -and ($removed[0].PSObject.Properties['Reason'])){
  $reasonCounts = $removed | Group-Object Reason | Sort-Object Count -Descending | Select-Object Name,Count
  Write-Host "[Finalize] Removal reasons:" -ForegroundColor Cyan
  $reasonCounts | ForEach-Object { Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor Gray }
}

# Provide a minimal csv preview (first 5)
Write-Host "[Finalize] Preview first 5 clean rows:" -ForegroundColor Cyan
$clean | Select-Object -First 5 | Format-Table -AutoSize
