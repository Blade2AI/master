<#!
.SYNOPSIS
  Wrapper to apply network anchoring (IPFS + Arweave) to an existing anchor JSON.
.DESCRIPTION
  Signs + PII-checks via sign_anchor.py first. Bundlr/IPFS remain DryRun-only unless policy flipped.
#>
[CmdletBinding()]
param(
  [string]$AnchorJsonPath,
  [switch]$DryRun,
  [string]$AnchorsDir = 'out/anchors'
)
$ErrorActionPreference='Stop'
Write-Host '== Apply-NetworkAnchors Wrapper ==' -ForegroundColor Cyan

# Resolve anchor JSON if not provided
if(-not $AnchorJsonPath){
  if(-not (Test-Path $AnchorsDir)){ throw "Anchors directory not found: $AnchorsDir" }
  $latest = Get-ChildItem -Path $AnchorsDir -Filter 'event_anchor_*.json' -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if(-not $latest){ throw 'No anchor JSON files found under {0}' -f $AnchorsDir }
  $AnchorJsonPath = $latest.FullName
  Write-Host "Auto-selected latest anchor: $AnchorJsonPath" -ForegroundColor DarkGray
}
if(-not (Test-Path $AnchorJsonPath)){ throw "Anchor JSON not found: $AnchorJsonPath" }

# Safety-first: sign (PII guardrail inside)
Write-Host '[ANCHOR] Signing anchor...' -ForegroundColor Cyan
python scripts/sign_anchor.py --anchor $AnchorJsonPath
if($LASTEXITCODE -ne 0){ throw '[ABORT] Signing failed – refusing to proceed.' }
Write-Host '[ANCHOR] Signature receipt created.' -ForegroundColor Green

# Policy: network off unless DryRun explicitly set, still skip actual uploads
if($DryRun){ Write-Host '[NET] DRY RUN – network uploads skipped by policy.' -ForegroundColor Yellow; return }
Write-Host '[POLICY] Live network anchoring is disabled. Re-run with -DryRun for signing only.' -ForegroundColor Red
