# File: scripts/Worker-Impact-Dashboard.psm1
# Purpose: Show-WorkerImpactDashboard - renders a console dashboard for a worker (stubbed)

function Show-WorkerImpactDashboard {
    param(
        [Parameter(Mandatory=$true)][string]$WorkerID,
        [string]$Station
    )

    Write-Host "Worker Impact Dashboard for $WorkerID" -ForegroundColor Cyan

    if (-not $Station) {
        if (Get-Command -Name Get-CurrentStation -ErrorAction SilentlyContinue) {
            $Station = Get-CurrentStation -WorkerID $WorkerID
        } else {
            $Station = 'UNKNOWN'
        }
    }

    $shift = (Get-Command -Name Get-CurrentShift -ErrorAction SilentlyContinue) ? (Get-CurrentShift) : 'SHIFT-UNKNOWN'
    $perf = (Get-Command -Name Get-WorkerPerformance -ErrorAction SilentlyContinue) ? (Get-WorkerPerformance -WorkerID $WorkerID -TimeWindow 'shift') : $null
    $impact = (Get-Command -Name Calculate-WorkerFinancialImpact -ErrorAction SilentlyContinue) ? (Calculate-WorkerFinancialImpact -WorkerID $WorkerID -Station $Station) : $null
    $suggestions = (Get-Command -Name Get-AIImprovementSuggestions -ErrorAction SilentlyContinue) ? (Get-AIImprovementSuggestions -WorkerID $WorkerID -Station $Station) : @()

    Write-Host "  Station: $Station" -ForegroundColor Gray
    Write-Host "  Shift: $shift" -ForegroundColor Gray

    if ($perf) {
        Write-Host "  Cycle Time: $($perf.CycleTime) seconds (target $($perf.TargetCycleTime))" -ForegroundColor White
        Write-Host "  Units/hr: $($perf.UnitsPerHour)" -ForegroundColor White
        Write-Host "  Quality: $($perf.QualityRate)" -ForegroundColor White
    }

    if ($impact) {
        Write-Host "  Net Contribution: $($impact.NetContribution)" -ForegroundColor White
        Write-Host "  Revenue: $($impact.Revenue)" -ForegroundColor White
    }

    if ($suggestions.Count -gt 0) {
        Write-Host "  Suggested Improvements:" -ForegroundColor Yellow
        foreach ($s in $suggestions) {
            Write-Host "    - $($s.Title): $($s.Description) (Potential $($s.PotentialValue))" -ForegroundColor Gray
        }
    }

    # Log view
    if (Get-Command -Name Log-GovernanceEvent -ErrorAction SilentlyContinue) {
        Log-GovernanceEvent -Event @{ type = 'WORKER_VIEW'; message = "Worker $WorkerID viewed dashboard"; worker = $WorkerID; station = $Station }
    }
}

Export-ModuleMember -Function *
