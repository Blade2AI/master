param([string]$Role = "Unknown")
$ErrorActionPreference = 'Stop'

$Base  = "C:\Sovereign"
$State = "$Base\state\last_shutdown_clean.json"
$Log   = "$Base\logs\shutdown.log"

function Log($m) {
    "$((Get-Date).ToString('s'))`t$env:COMPUTERNAME`t$m" | Out-File -FilePath $Log -Append -Encoding utf8
    Write-Host $m
}

Log "=== REPLICANT SHUTDOWN $env:COMPUTERNAME ($Role) ==="

# Graceful supervisor stop placeholder
Log "Stopping replicant supervisor (placeholder)."
# & "$Base\scripts\Stop-Replicant-Role.ps1" -Role $Role -ErrorAction SilentlyContinue

Log "Sealing ledger / receipts (placeholder)."
# & "$Base\scripts\Finalize-Ledger.ps1" -Role $Role -ErrorAction SilentlyContinue

Log "Flagging shutdown as clean."
@{ clean = $true; timestamp = (Get-Date).ToString('o'); role = $Role } | ConvertTo-Json -Compress | Set-Content $State -Encoding utf8

Log "Graceful shutdown preparations complete."