param([int]$LookbackMinutes=10)
$ErrorActionPreference='Stop'
$Base='C:\Sovereign'
$LedgerDir="$Base\ledger\blocks"
$HeartbeatLog="$Base\ledger\heartbeat.log"
$LogFile="$Base\logs\archival_heartbeat.log"

function Log($m){"$((Get-Date).ToString('s'))`t$env:COMPUTERNAME`t$m" | Out-File -FilePath $LogFile -Append -Encoding utf8; Write-Host $m }

function H256($data){ if($data -is [string]){ $b=[Text.Encoding]::UTF8.GetBytes($data) } else { $b=$data }; $h=[Security.Cryptography.SHA256]::Create().ComputeHash($b); ($h|ForEach-Object ToString x2) -join '' }
function H3-512($data){ try{ if($data -is [string]){ $b=[Text.Encoding]::UTF8.GetBytes($data) } else { $b=$data }; $h=[Security.Cryptography.SHA3_512]::Create().ComputeHash($b); ($h|ForEach-Object ToString x2) -join '' } catch { Log 'WARN: SHA3-512 unavailable – fallback to SHA256-only'; return H256 $data } }
function Get-CanonPath($fullPath){ $relative=$fullPath.Substring($Base.Length+1).Replace('\\','/'); $lower=$relative.ToLowerInvariant(); $nfc=$lower.Normalize([Text.NormalizationForm]::FormC); return $nfc.TrimEnd('/') }
function New-LeafHash($canonPath,$contentHash256){ $dual=$contentHash256 + (H3-512 $contentHash256); return H256("$canonPath`:$dual") }
$Global:PadLeaf = H256('MERKLE_PAD_V1')
function Get-MerkleRoot([string[]]$leaf){ if($leaf.Count -eq 0){ return '0'*64 }; if($leaf.Count -eq 1){ return $leaf[0] }; $parents=@(); for($i=0;$i -lt $leaf.Count;$i+=2){ $l=$leaf[$i]; $r= if($i+1 -lt $leaf.Count){ $leaf[$i+1] } else { $Global:PadLeaf }; $parents += H256($l+$r) } return Get-MerkleRoot $parents }

if(-not (Test-Path $LedgerDir)){ Log "Ledger dir missing: $LedgerDir"; exit 1 }
$cutoff=(Get-Date).AddMinutes(-$LookbackMinutes)
$recent=Get-ChildItem -Path $LedgerDir -File | Where-Object { $_.LastWriteTime -ge $cutoff } | Sort-Object LastWriteTime
if(-not $recent){ Log "No recent blocks in past $LookbackMinutes min."; exit 0 }

# Build leaf hashes (prefer embedded block.hash; fallback to file hash)
$hashes=@(); $manifest=@()
foreach($b in $recent){
  try {
    $json=Get-Content $b.FullName -Raw | ConvertFrom-Json
    $h256= if($json.hash){ $json.hash } else { (Get-FileHash -Algorithm SHA256 -LiteralPath $b.FullName).Hash }
  } catch { $h256=(Get-FileHash -Algorithm SHA256 -LiteralPath $b.FullName).Hash }
  $canon=Get-CanonPath $b.FullName
  $hashes += (New-LeafHash $canon $h256)
  $manifest += [pscustomobject]@{ path=$canon; sha256=$h256; sha3_512=(H3-512 $h256); size=$b.Length; modified=$b.LastWriteTimeUtc.ToString('o') }
}
$root=Get-MerkleRoot $hashes
$rangeStart=$recent[0].Name; $rangeEnd=$recent[-1].Name

# Prepare heartbeat payload routed through central recorder
$heartbeatPayload = [ordered]@{
  range_start = $rangeStart
  range_end   = $rangeEnd
  merkle_root = $root
  leaves      = $hashes.Count
  generated_utc = (Get-Date).ToUniversalTime().ToString('o')
}

# Legacy local append for node-local continuity (still kept minimal)
$record=@{ timestamp=(Get-Date).ToString('o'); node=$env:COMPUTERNAME; range_start=$rangeStart; range_end=$rangeEnd; merkle_root=$root; status='PENDING_REMOTE' } | ConvertTo-Json -Compress
$record | Out-File -FilePath $HeartbeatLog -Append -Encoding utf8
Log "Heartbeat recorded root=$root range=$rangeStart->$rangeEnd (leaves=$($hashes.Count))"

# Emit manifest file (unchanged behavior)
$manPath=Join-Path $LedgerDir ("manifest_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".json")
$manifest | ConvertTo-Json -Depth 4 | Out-File -FilePath $manPath -Encoding utf8

# Route heartbeat + manifest summary through recorder unified event logger
try {
  & scripts/Write-Event.ps1 -EventType 'heartbeat' -Payload $heartbeatPayload
  & scripts/Write-Event.ps1 -EventType 'manifest' -Payload @{ merkle_root=$root; range_start=$rangeStart; range_end=$rangeEnd; file_count=$manifest.Count; manifest_path=$manPath }
  Log "Recorder events emitted (heartbeat + manifest)."
} catch { Log "ERROR emitting recorder events: $_" }