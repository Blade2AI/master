param([string]$Role = "Unknown")
$ErrorActionPreference = 'Stop'

$Base  = "C:\Sovereign"
$State = "$Base\state\last_shutdown_clean.json"
$Log   = "$Base\logs\startup.log"

function Log($m) {
    "$((Get-Date).ToString('s'))`t$env:COMPUTERNAME`t$m" | Out-File -FilePath $Log -Append -Encoding utf8
    Write-Host $m
}

Log "=== REPLICANT BOOT $env:COMPUTERNAME ($Role) ==="

foreach ($p in "$Base\state","$Base\logs") {
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# 1) Inspect previous state (if any) BEFORE overwriting
$unclean = $true
if (Test-Path $State) {
    try {
        $prev = Get-Content $State -Raw | ConvertFrom-Json
        if ($prev.clean -eq $true) { $unclean = $false }
    } catch { Log "WARN: Failed to parse previous state JSON, treating as unclean." }
} else {
    Log "No previous state file found – treating as first boot / unclean."
}

# 2) Mark THIS session as not yet clean
@{ clean = $false; boot = (Get-Date).ToString('o'); role = $Role } | ConvertTo-Json -Compress | Set-Content $State -Encoding utf8

# 3) Integrity checks (Full if unclean, Light if clean)
if ($unclean) {
    Log "UNCLEAN shutdown detected ? full integrity checks + Safe Mode"
    & "$Base\scripts\Run-IntegrityChecks.ps1" -Mode Full -Role $Role
} else {
    Log "Clean shutdown detected ? light checks only"
    & "$Base\scripts\Run-IntegrityChecks.ps1" -Mode Light -Role $Role
}

# Role-based service start placeholders
switch ($Role) {
    'ModelRAG' { Log "Starting model / embedding services (placeholder)." }
    'Runtime'  { Log "Starting orchestration runtime (placeholder)." }
    'UI'       { Log "Starting Boardroom UI services (placeholder)." }
    'Archival' { Log "Starting archival / heartbeat services (placeholder)." }
    default    { Log "Unknown role – minimal services only." }
}

# Boardroom backend placeholder
Log "Starting Boardroom backend (placeholder)."
# & "$Base\scripts\Start-Boardroom.ps1" -Role $Role  # Uncomment when script exists

# Replicant supervisor placeholder
Log "Starting Replicant supervisor (SafeMode=$unclean) (placeholder)."
# & "$Base\scripts\Start-Replicant-Role.ps1" -Role $Role -SafeMode:$unclean  # Uncomment when script exists

Log "Startup script completed (node marked not-clean until graceful Stop-Replicant.ps1 executes)."