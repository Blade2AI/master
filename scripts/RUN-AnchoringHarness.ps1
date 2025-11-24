<#!
.SYNOPSIS
  Minimal anchoring harness (DRY-RUN only).
.DESCRIPTION
  Ensures a ledger snapshot exists, invokes Seal-And-Anchor-Dual.ps1 with -DryRun.
  No network writes; Bundlr/IPFS guarded by Perform-NetworkAnchoring.
#>
[CmdletBinding()]param(
  [string]$LedgerPath = 'docs/audit/ledger_snapshot.json',
  [string]$OutDir = 'out/anchors',
  [string]$Environment = 'proof'
)
$ErrorActionPreference='Stop'
Write-Host '== RUN-AnchoringHarness (DRY-RUN) ==' -ForegroundColor Cyan
if(-not (Test-Path $OutDir)){ New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }
if(-not (Test-Path $LedgerPath)){
  Write-Host "Ledger snapshot missing. Creating stub at $LedgerPath" -ForegroundColor Yellow
  $stub = @{ snapshot_version='proof-auto'; events=@(); meta=@{ note='Auto-generated stub for dry-run anchoring.' } }
  $dir = Split-Path $LedgerPath -Parent; if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $stub | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $LedgerPath -Encoding UTF8
}
$sealScript = 'scripts/Seal-And-Anchor-Dual.ps1'
if(-not (Test-Path $sealScript)){ throw "Seal script not found: $sealScript" }
Write-Host "Invoking seal script (dry-run) on $LedgerPath" -ForegroundColor Cyan
pwsh -File $sealScript -LedgerPath $LedgerPath -Environment $Environment -DryRun
Write-Host '[DONE] Dry-run anchoring complete.' -ForegroundColor Green
