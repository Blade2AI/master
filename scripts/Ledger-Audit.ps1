Write-Host "=== Ledger Audit ===" -ForegroundColor Cyan
$ledger = 'boardroom_ledger.jsonl'
if(-not (Test-Path $ledger)){ Write-Warning "Ledger file missing: $ledger"; return }
$prevHash = $null
$lineNo = 0
Get-Content $ledger | ForEach-Object {
  $lineNo++
  $raw = $_.Trim()
  if(-not $raw){ return }
  try {
    $obj = $raw | ConvertFrom-Json
  } catch {
    Write-Warning "Line $lineNo invalid JSON"; return
  }
  $payload = @{ previous_entry_hash = $obj.previous_entry_hash; event_type = $obj.event_type; payload = $obj.payload; timestamp = $obj.timestamp; signer = $obj.signer }
  $canonical = ($payload | ConvertTo-Json -Depth 8) -replace '\s+', ''
  $sha = [System.BitConverter]::ToString((New-Object System.Security.Cryptography.SHA256Managed).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($canonical))) -replace '-',''
  if($sha -ne $obj.entry_id){ Write-Warning "Hash mismatch line $lineNo" } else { Write-Host "Line $lineNo OK" -ForegroundColor Green }
  if($obj.previous_entry_hash -ne $prevHash -and $prevHash){ Write-Warning "Chain break at line $lineNo" }
  $prevHash = $obj.entry_id
}
