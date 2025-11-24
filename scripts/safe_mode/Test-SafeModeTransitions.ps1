# Test-SafeModeTransitions.ps1
# Dry-run simulator for Sovereign Safe Mode transitions.

[CmdletBinding()]
param(
    [ValidateSet("NormalToSafeToNormal", "IncidentEscalation", "LockdownScenario")]
    [string]$Scenario = "NormalToSafeToNormal",

    [string]$LogPath = "C:\BladeOps\logs\SafeModeSimulator.log"
)

$ErrorActionPreference = "Stop"

# --- State machine definition ---

$states = @("Normal", "Safe", "Elevated", "LockedDown")

$transitions = @{
    "Normal" = @("Safe", "Elevated")
    "Safe" = @("Normal", "Elevated", "LockedDown")
    "Elevated" = @("Safe", "LockedDown", "Normal")
    "LockedDown" = @("Safe")   # Strict: must step via Safe to return to Normal
}

function Invoke-Transition {
    param(
        [string]$From,
        [string]$To,
        [string]$Reason
    )

    if (-not $states.Contains($From)) {
        throw "Invalid 'from' state: $From"
    }
    if (-not $states.Contains($To)) {
        throw "Invalid 'to' state: $To"
    }

    $allowed = $transitions[$From]
    if (-not $allowed -or -not $allowed.Contains($To)) {
        throw "Illegal transition: $From ? $To (not in allowed list: $($allowed -join ', '))"
    }

    $timestamp = Get-Date -Format "o"
    $entry = "[{0}] SIMULATED TRANSITION: {1} ? {2} | Reason: {3}" -f $timestamp, $From, $To, $Reason
    Write-Host $entry -ForegroundColor Cyan
    Add-Content -Path $LogPath -Value $entry

    return $To
}

# --- Scenario definitions ---

$current = "Normal"
$startMsg = "[{0}] Starting SafeMode simulation. Scenario: {1}, Initial state: {2}" -f (Get-Date -Format "o"), $Scenario, $current
Write-Host $startMsg -ForegroundColor Green
Add-Content -Path $LogPath -Value $startMsg

switch ($Scenario) {
    "NormalToSafeToNormal" {
        $current = Invoke-Transition -From $current -To "Safe" -Reason "Operator overload / uncertainty."
        $current = Invoke-Transition -From $current -To "Normal" -Reason "Review complete, system stable."
    }
    "IncidentEscalation" {
        $current = Invoke-Transition -From $current -To "Safe" -Reason "Possible anomaly detected in logs."
        $current = Invoke-Transition -From $current -To "Elevated" -Reason "Incident investigation required."
        $current = Invoke-Transition -From $current -To "Safe" -Reason "Mitigations applied; verify stability."
        $current = Invoke-Transition -From $current -To "Normal" -Reason "All checks passed."
    }
    "LockdownScenario" {
        $current = Invoke-Transition -From $current -To "Safe" -Reason "Suspected compromise of credentials."
        $current = Invoke-Transition -From $current -To "LockedDown" -Reason "Legal/forensic preservation required."
        $current = Invoke-Transition -From $current -To "Safe" -Reason "Forensic review completed; controlled recovery."
        $current = Invoke-Transition -From $current -To "Normal" -Reason "System integrity confirmed."
    }
}

$endMsg = "[{0}] Scenario complete. Final state: {1}" -f (Get-Date -Format "o"), $current
Write-Host $endMsg -ForegroundColor Yellow
Add-Content -Path $LogPath -Value $endMsg
