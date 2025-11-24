param([string]$Node='PC-D')
$ErrorActionPreference='Stop'

$baseUNC="\\$Node\C$\Sovereign"
$hbFile=Join-Path $baseUNC 'ledger\heartbeat.log'
$ledgerDir=Join-Path $baseUNC 'ledger\blocks'

if(-not (Test-Path $hbFile)){ Write-Error "Heartbeat log not found: $hbFile"; exit 1 }
if(-not (Test-Path $ledgerDir)){ Write-Error "Ledger blocks dir not found: $ledgerDir"; exit 1 }

# Dual-hash helpers (mirror node logic)
function H256($data){ if($data -is [string]){ $b=[Text.Encoding]::UTF8.GetBytes($data) } else { $b=$data }; $h=[Security.Cryptography.SHA256]::Create().ComputeHash($b); ($h|ForEach-Object ToString x2) -join '' }
function H3-512($data){ try{ if($data -is [string]){ $b=[Text.Encoding]::UTF8.GetBytes($data) } else { $b=$data }; $h=[Security.Cryptography.SHA3_512]::Create().ComputeHash($b); ($h|ForEach-Object ToString x2) -join '' } catch { return H256 $data } }
function Get-CanonPath($root,$full){ $relative=$full.Substring($root.Length+1).Replace('\\','/'); $lower=$relative.ToLowerInvariant(); $nfc=$lower.Normalize([Text.NormalizationForm]::FormC); return $nfc.TrimEnd('/') }
function New-LeafHash($canon,$h256){ $dual=$h256 + (H3-512 $h256); return H256("$canon`:$dual") }
$Global:PadLeaf = H256('MERKLE_PAD_V1')
function Get-MerkleRoot([string[]]$leaf){ if($leaf.Count -eq 0){ return '0'*64 }; if($leaf.Count -eq 1){ return $leaf[0] }; $parents=@(); for($i=0;$i -lt $leaf.Count;$i+=2){ $l=$leaf[$i]; $r= if($i+1 -lt $leaf.Count){ $leaf[$i+1] } else { $Global:PadLeaf }; $parents += H256($l+$r) } return Get-MerkleRoot $parents }

$lines=Get-Content $hbFile
$results=@()
foreach($line in $lines){
  $hb=$null; try { $hb=$line | ConvertFrom-Json } catch { continue }
  $start=$hb.range_start; $end=$hb.range_end; $expected=$hb.merkle_root
  $blocks=Get-ChildItem $ledgerDir -File | Sort-Object Name | Where-Object { $_.Name -ge $start -and $_.Name -le $end }
  $leaf=@()
  foreach($b in $blocks){
    $h256=$null
    try { $json=Get-Content $b.FullName -Raw | ConvertFrom-Json; if($json.hash){ $h256=$json.hash } } catch { }
    if(-not $h256){ $h256=(Get-FileHash -Algorithm SHA256 -LiteralPath $b.FullName).Hash }
    $canon=Get-CanonPath (Join-Path $baseUNC '') $b.FullName
    $leaf += (New-LeafHash $canon $h256)
  }
  $actual= if($leaf.Count -gt 0){ Get-MerkleRoot $leaf } else { '(none)' }
  $status= if($actual -eq $expected){ 'OK' } else { 'MISMATCH' }
  $results += [pscustomobject]@{ timestamp=$hb.timestamp; start=$start; end=$end; expected=$expected; actual=$actual; status=$status }
}
$results | Sort-Object timestamp | Format-Table -AutoSize