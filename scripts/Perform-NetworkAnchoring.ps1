<#!
.SYNOPSIS
  Perform network anchoring for a sealed manifest.
.DESCRIPTION
  Default: Dry-run (no network writes). Live only if all guards pass.
  Integrates Arweave (Bundlr) and IPFS harness scripts (both dry-run capable).
#>
[CmdletBinding()]param(
  [Parameter(Mandatory=$true)][string]$ManifestPath,
  [switch]$Live,
  [switch]$DryRun
)
$ErrorActionPreference='Stop'
Write-Host '== Perform-NetworkAnchoring ==' -ForegroundColor Cyan
Write-Host "Manifest : $ManifestPath"
Write-Host ("Live     : {0}" -f $Live.IsPresent)
Write-Host ("DryRun   : {0}" -f $DryRun.IsPresent)

if(-not (Test-Path $ManifestPath)){ throw "Manifest not found: $ManifestPath" }
$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$anchorId = $manifest.anchor_id; if(-not $anchorId){ $anchorId = [IO.Path]::GetFileNameWithoutExtension($ManifestPath) }
$rootHash = $manifest.root_hash

# Signing + PII guardrail
try {
  Write-Host '[ANCHOR] Signing + PII guardrail...' -ForegroundColor Cyan
  python scripts/sign_anchor.py --anchor $ManifestPath
  if($LASTEXITCODE -ne 0){ throw 'sign_anchor.py returned non-zero' }
  Write-Host '[ANCHOR] Signature OK.' -ForegroundColor Green
} catch { throw "[ABORT] Signing/guard failed: $_" }

$effectiveDryRun = $true
$fallbackReasons = @()
if($DryRun){ $fallbackReasons += 'EXPLICIT_DRYRUN' }
elseif(-not $Live){ $fallbackReasons += 'LIVE_FLAG_NOT_SET' }
else {
  if($env:ANCHOR_ENV -ne 'prod'){ $fallbackReasons += 'ANCHOR_ENV_NOT_PROD' }
  if([string]::IsNullOrWhiteSpace($env:NFT_STORAGE_API_KEY)){ $fallbackReasons += 'MISSING_NFT_STORAGE_API_KEY' }
  $bundlrKeyPath = $env:BUNDLR_KEY_PATH
  if([string]::IsNullOrWhiteSpace($bundlrKeyPath) -or -not (Test-Path $bundlrKeyPath)){ $fallbackReasons += 'MISSING_OR_INVALID_BUNDLR_KEY' }
  $sigPath = [IO.Path]::ChangeExtension($ManifestPath,'.sig.json')
  if(-not (Test-Path $sigPath)){ $fallbackReasons += 'MISSING_SIGNATURE_FILE' }
  if($fallbackReasons.Count -eq 0){ $effectiveDryRun = $false }
}

if($effectiveDryRun){ Write-Host 'Mode     : DRY-RUN' -ForegroundColor Yellow; if($fallbackReasons.Count -gt 0){ Write-Host "Guards   : $($fallbackReasons -join ', ')" -ForegroundColor DarkYellow } } else { Write-Host 'Mode     : LIVE (ALL GUARDS PASSED)' -ForegroundColor Green }

$txId = $null; $cid = $null

# Arweave (Bundlr) harness
$invokeAr = Join-Path $PSScriptRoot 'Invoke-ArweaveAnchor.ps1'
if(Test-Path $invokeAr){
  try {
    $arRes = & $invokeAr -ManifestPath $ManifestPath -DryRun:$effectiveDryRun
    $txId = $arRes.TxId
  } catch { Write-Host "[WARN] Arweave harness failed: $_" -ForegroundColor Yellow; $fallbackReasons += 'ARWEAVE_EXCEPTION'; $effectiveDryRun = $true }
} else { Write-Host '[INFO] Arweave harness missing; skipping.' -ForegroundColor DarkGray }

# IPFS harness
$invokeIpfs = Join-Path $PSScriptRoot 'Invoke-IpfsUpload.ps1'
if(Test-Path $invokeIpfs){
  try {
    $ipfsRes = & $invokeIpfs -ManifestPath $ManifestPath -DryRun:$effectiveDryRun
    $cid = $ipfsRes.Cid
  } catch { Write-Host "[WARN] IPFS harness failed: $_" -ForegroundColor Yellow; $fallbackReasons += 'IPFS_EXCEPTION'; $effectiveDryRun = $true }
} else { Write-Host '[INFO] IPFS harness missing; skipping.' -ForegroundColor DarkGray }

if(-not $effectiveDryRun -and $txId -and $cid){
  $eventPayload = @{
    anchor_id   = $anchorId
    root_hash   = $rootHash
    tx_id       = $txId
    cid         = $cid
    created_utc = (Get-Date).ToUniversalTime().ToString('o')
    manifest    = $ManifestPath
  }
  $eventPath = Join-Path (Split-Path $ManifestPath -Parent) ("event_anchor_created_$anchorId.json")
  $eventPayload | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $eventPath -Encoding UTF8
  $writeEvent = 'scripts/Write-Event.ps1'
  if(Test-Path $writeEvent){ try { & $writeEvent -EventType 'event_anchor_created' -Payload @{ anchor_id=$anchorId; root_hash=$rootHash; tx_id=$txId; cid=$cid; created_utc=$eventPayload.created_utc } } catch { Write-Host "[WARN] Event emission failed: $_" -ForegroundColor Yellow } }
  Write-Host ("[ANCHOR-LIVE-01] MODE=LIVE anchor_id={0} tx_id={1} cid={2} root={3}" -f $anchorId,$txId,$cid,$rootHash) -ForegroundColor Green
} else {
  Write-Host '[ANCHOR] No live receipts (dry-run / guards not met).' -ForegroundColor Yellow
  Write-Host ("[ANCHOR-LIVE-01] MODE=DRYRUN anchor_id={0} root={1} reasons={2}" -f $anchorId,$rootHash,($fallbackReasons -join '|')) -ForegroundColor Yellow
}
