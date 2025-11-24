# File: scripts/Truth-Test.psm1
# Purpose: Invoke-TruthTest implementation (uses Core-Sovereign-Data stubs if present)

function Invoke-TruthTest {
    param(
        [Parameter(Mandatory=$false)][string]$MetricCategory = "Financial",
        [Parameter(Mandatory=$false)][datetime]$StartDate = (Get-Date).AddMonths(-3),
        [Parameter(Mandatory=$false)][datetime]$EndDate = (Get-Date)
    )

    Write-Host "Running truth test for category $MetricCategory from $StartDate to $EndDate" -ForegroundColor Cyan

    # Attempt to call data helpers; fall back to defaults
    try {
        $dateRange = @{ start = $StartDate; end = $EndDate }
        $audits = @()
        if (Get-Command -Name Get-SovereignAudit -ErrorAction SilentlyContinue) {
            $audits = Get-SovereignAudit -DateRange $dateRange -EventType $MetricCategory
        }

        $metricValue = 0
        if (Get-Command -Name Get-MetricValue -ErrorAction SilentlyContinue) {
            $metricValue = Get-MetricValue -Name $MetricCategory -Date $EndDate
        }

        # Basic heuristic: if metric value is non-zero but cashflow shows zero => watermelon
        $cashFlow = @{ OperatingActivities = 0 }
        if (Get-Command -Name Get-CashFlowStatement -ErrorAction SilentlyContinue) {
            $cashFlow = Get-CashFlowStatement -DateRange $dateRange
        }

        $isWatermelon = $false
        if ($metricValue -gt 0 -and $cashFlow.OperatingActivities -eq 0) { $isWatermelon = $true }

        $report = [pscustomobject]@{
            Status = (if ($isWatermelon) { 'ALERT' } else { 'OK' })
            MetricCategory = $MetricCategory
            MetricValue = $metricValue
            CashFlow = $cashFlow
            ConstitutionalAction = (if ($isWatermelon) { 'Escalate to Boardroom13' } else { 'None' })
            Timestamp = (Get-Date).ToString('o')
        }

        # Sign the report if signing available
        if (Get-Command -Name New-MessageSignature -ErrorAction SilentlyContinue) {
            $sig = New-MessageSignature -Data $report
            $report | Add-Member -NotePropertyName Signature -NotePropertyValue $sig
        }

        # Log governance event if logger present
        if (Get-Command -Name Log-GovernanceEvent -ErrorAction SilentlyContinue) {
            Log-GovernanceEvent -Event @{ type = 'TRUTH_TEST'; message = "Truth test run: $($report.Status)"; report = $report }
        }

        return $report
    } catch {
        Write-Warning "Truth test failed: $_"
        return [pscustomobject]@{ Status = 'ERROR'; Error = $_.ToString() }
    }
}

Export-ModuleMember -Function *
