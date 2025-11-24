<#!
.SYNOPSIS
  IPFS upload harness (DRY-RUN ONLY for now).
.DESCRIPTION
  Reads an anchor manifest (list of payload descriptors) and produces a dry-run
  IPFS result file <manifest>.ipfs_result.json with fake CIDs. No network calls.
.PARAMETER ManifestPath
  Path to anchor manifest JSON.
.PARAMETER DryRun
  If set (or passed true) produces DRYRUN status (currently always dry-run).
#>
[CmdletBinding()]param(
  [Parameter(Mandatory=$true)][string]$ManifestPath,
  [switch]$DryRun
)
$ErrorActionPreference='Stop'
Write-Host '=== Invoke-IpfsUpload (DRY-RUN Harness) ===' -ForegroundColor Cyan
Write-Host "Manifest : $ManifestPath"
Write-Host "DryRun   : $($DryRun.IsPresent)"
if(-not (Test-Path $ManifestPath)){ throw "Manifest not found: $ManifestPath" }

$raw = Get-Content -LiteralPath $ManifestPath -Raw
try { $manifestData = $raw | ConvertFrom-Json } catch { throw "Failed to parse manifest JSON: $_" }
if($manifestData -isnot [System.Collections.IEnumerable]){ $manifestData = @($manifestData) }

$results = @()
foreach($item in $manifestData){
  $payloadPath = $item.payload_path
  if(-not $payloadPath){ Write-Warning "Skipping manifest entry without payload_path"; continue }
  $resolved = Resolve-Path -LiteralPath $payloadPath -ErrorAction SilentlyContinue
  if(-not $resolved){
    Write-Warning "Payload not found: $payloadPath"
    $results += [PSCustomObject]@{ Status='ERROR'; File=$payloadPath; Cid=$null; Error='File not found' }
    continue
  }
  $cid = 'dryrun-' + ([guid]::NewGuid().ToString('N'))
  Write-Host "[DRY-RUN] Would IPFS pin: $($resolved.Path) -> CID: $cid" -ForegroundColor Yellow
  $results += [PSCustomObject]@{ Status='DRYRUN'; File=$resolved.Path; Cid=$cid; Error=$null }
}

$outFile = "$ManifestPath.ipfs_result.json"
$results | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $outFile -Encoding UTF8
Write-Host "[INFO] IPFS results written: $outFile" -ForegroundColor Cyan

$first = $results | Select-Object -First 1
return [PSCustomObject]@{ Status=$first.Status; File=$first.File; Cid=$first.Cid; Error=$first.Error; ResultsFile=$outFile }