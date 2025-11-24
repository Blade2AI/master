param(
  [ValidateSet('Full','Light')][string]$Mode = 'Light',
  [string]$Role = 'Unknown'
)
$ErrorActionPreference = 'Stop'

$Base = 'C:\Sovereign'
$Log  = "$Base\logs\integrity-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Simple logger to file and console
function Log($m){"$((Get-Date).ToString('s'))`t$env:COMPUTERNAME`t$Role`t$m" | Out-File -FilePath $Log -Append -Encoding utf8; Write-Host $m }

# =====================
# Dual-hash Merkle core
# =====================
# SHA256 (always available)
function H256($data){ if($data -is [string]){ $b=[Text.Encoding]::UTF8.GetBytes($data) } else { $b=$data }; $h=[Security.Cryptography.SHA256]::Create().ComputeHash($b); ($h|ForEach-Object ToString x2) -join '' }
# SHA3-512 (fallback to SHA256 if unavailable on older .NET)
function H3-512($data){ try{ if($data -is [string]){ $b=[Text.Encoding]::UTF8.GetBytes($data) } else { $b=$data }; $h=[Security.Cryptography.SHA3_512]::Create().ComputeHash($b); ($h|ForEach-Object ToString x2) -join '' } catch { Log 'WARN: SHA3-512 unavailable – fallback to SHA256-only mode'; return H256 $data } }
# Canonicalize file path relative to $Base (lowercase + NFC) to defeat path spoofing
function Get-CanonPath($fullPath){ $relative=$fullPath.Substring($Base.Length+1).Replace('\\','/'); $lower=$relative.ToLowerInvariant(); $nfc=$lower.Normalize([Text.NormalizationForm]::FormC); return $nfc.TrimEnd('/') }
# Leaf hash = H256( canonPath ":" (sha256(file) + sha3_512(sha256(file))) )
function New-LeafHash($canonPath,$contentHash256){ $contentDual = $contentHash256 + (H3-512 $contentHash256); return H256("$canonPath`:$contentDual") }
# Fixed padding leaf (no odd-leaf duplication attack)
$Global:PadLeaf = H256('MERKLE_PAD_V1')
# Pairwise up tree with fixed padding
function Get-MerkleRoot([string[]]$leafHashes){ if($leafHashes.Count -eq 0){ return '0'*64 }; if($leafHashes.Count -eq 1){ return $leafHashes[0] }; $parents=@(); for($i=0;$i -lt $leafHashes.Count;$i+=2){ $left=$leafHashes[$i]; $right= if($i+1 -lt $leafHashes.Count){ $leafHashes[$i+1] } else { $Global:PadLeaf }; $parents += H256($left+$right) }; return Get-MerkleRoot $parents }

Log "=== INTEGRITY CHECK START ($Mode) ==="

# Critical material to attest
$CriticalRoots = @(
  "$Base\scripts",
  "$Base\policy",
  "$Base\ledger\immutable",
  "$Base\state"
) | Where-Object { Test-Path $_ }

# Build dual-hash Merkle root over canonicalized paths
$CriticalFiles = Get-ChildItem -Recurse -File -Path $CriticalRoots -ErrorAction SilentlyContinue | Sort-Object FullName
$LeafHashes = foreach($f in $CriticalFiles){ $h256=(Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName).Hash; $canon=Get-CanonPath $f.FullName; New-LeafHash $canon $h256 }
$CurrentMerkleRoot = Get-MerkleRoot $LeafHashes
$sha3Mode = if((H3-512 'probe') -ne $null){ 'enabled' } else { 'fallback' }
Log "Dual-hash Merkle root: $CurrentMerkleRoot  (leaves=$($LeafHashes.Count), SHA3=$sha3Mode)"

$lastGoodFile = "$Base\state\last_known_good_root.txt"
$anchorFile   = "$Base\state\last_anchor.json"   # { "txid": "<arweave_txid>" }

# Light mode: local last-known-good compare
if($Mode -eq 'Light'){
  if(Test-Path $lastGoodFile){
    $expected=(Get-Content $lastGoodFile -Raw).Trim()
    if($CurrentMerkleRoot -eq $expected){ Log 'Light check PASSED'; Log "=== INTEGRITY CHECK END ($Mode) ==="; return } else { Log 'Light check FAILED (mismatch) – escalating to Full' }
  } else { Log 'No last known good root – escalating to Full' }
}

# Full mode: try remote anchor (Arweave) then fallback to local
Log 'Entering Full verification'
$verified=$false
if(Test-Path $anchorFile){
  try {
    $anchor=Get-Content $anchorFile -Raw | ConvertFrom-Json
    $txid=$anchor.txid; Log "Fetching Arweave anchor: $txid"
    $resp=Invoke-WebRequest -Uri "https://arweave.net/tx/$txid" -TimeoutSec 30 -UseBasicParsing
    $json=$resp.Content | ConvertFrom-Json
    # Arweave tx.data is base64url – decode to get anchored root string
    $data64=$json.data -replace '-','+' -replace '_','/'
    $pad=(4 - $data64.Length % 4) % 4; if($pad -gt 0){ $data64 += '=' * $pad }
    $bytes=[Convert]::FromBase64String($data64)
    $anchoredRoot=[System.Text.Encoding]::UTF8.GetString($bytes).Trim()
    if($anchoredRoot -eq $CurrentMerkleRoot){ Log 'Arweave anchor VERIFIED'; $verified=$true } else { Log "Arweave MISMATCH anchored=$anchoredRoot current=$CurrentMerkleRoot" }
  } catch { Log "Arweave fetch failed: $($_.Exception.Message) – skipping remote verify" }
} else { Log 'No Arweave anchor file – local verify only' }

if(-not $verified -and (Test-Path $lastGoodFile)){
  $expected=(Get-Content $lastGoodFile -Raw).Trim(); if($CurrentMerkleRoot -eq $expected){ Log 'Local fallback PASSED'; $verified=$true } else { Log 'Local fallback FAILED' }
}

if($verified){ $CurrentMerkleRoot | Set-Content $lastGoodFile -Encoding utf8; Log 'Updated last known good root' } else { Log 'Integrity check FAILED – recommend Safe Mode / manual audit' }
Log "=== INTEGRITY CHECK END ($Mode) ==="