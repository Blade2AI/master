param (
    [string]$GenesisArweaveTx,
    [string]$GenesisIpfsCid
)
$ErrorActionPreference = 'Stop'
function Fetch-Payload($url) { (Invoke-WebRequest $url -UseBasicParsing).Content.Trim() }
if(-not $GenesisArweaveTx -or -not $GenesisIpfsCid){ throw 'Genesis TX/CID required' }
$expectedPrevArweave = $GenesisArweaveTx.PadRight(64,'0')
$expectedPrevIpfs    = $GenesisIpfsCid.PadRight(64,'0')
$currentArweave = $GenesisArweaveTx
$currentIpfs    = $GenesisIpfsCid
while ($true) {
    $arweavePayload = Fetch-Payload "https://arweave.net/$currentArweave"
    $ipfsPayload    = Fetch-Payload "https://$currentIpfs.ipfs.nftstorage.link/"
    if ($arweavePayload -ne $ipfsPayload) { throw "Chain mismatch at $currentArweave / $currentIpfs" }
    $lines = $arweavePayload -split "`n"
    if($lines.Count -lt 6){ throw "Unexpected payload format at $currentArweave" }
    if ($lines[4] -ne $expectedPrevArweave -or $lines[5] -ne $expectedPrevIpfs) { throw 'Previous anchor link broken' }
    Write-Host "[OK] Verified $currentArweave / $currentIpfs" -ForegroundColor Green
    if ($lines[0] -match '^0{128}$') { Write-Host '[TERMINUS] ZERO-ROOT REACHED – CHAIN COMPLETE' -ForegroundColor Cyan; break }
    $expectedPrevArweave = $currentArweave
    $expectedPrevIpfs    = $currentIpfs
    $currentArweave = $lines[4]
    $currentIpfs    = $lines[5]
}
