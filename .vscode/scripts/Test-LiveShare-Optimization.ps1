param(
    [string[]]$TargetPCs = @('pc-1','pc-2','pc-3','pc-4'),
    [switch]$AutoDiscover,
    [switch]$TestOnly,
    [switch]$ShowDetailedMetrics,
    [int]$PingCount = 8
)

# Import network utilities
$networkUtils = Join-Path $PSScriptRoot "Network-Utils.ps1"
if (Test-Path $networkUtils) {
    . $networkUtils
}

#region Helper Functions
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $time = Get-Date -Format "HH:mm:ss"
    $colors = @{ "ERROR" = "Red"; "WARN" = "Yellow"; "SUCCESS" = "Green"; "INFO" = "White" }
    Write-Host "[$time] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Test-LiveShareOptimization {
    param([string]$ComputerName)
    
    Write-Log "?? Testing Live Share optimization on $ComputerName..." "INFO"
    
    try {
        $result = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $results = @{
                VSCodeInstalled = $false
                LiveShareInstalled = $false
                LANModeConfigured = $false
                FirewallConfigured = $false
                PortsOpen = @()
                Settings = @{}
            }
            
            # Check VS Code installation
            if (Get-Command code -ErrorAction SilentlyContinue) {
                $results.VSCodeInstalled = $true
                
                # Check Live Share extension
                $extensions = & code --list-extensions 2>$null
                if ($extensions -match "ms-vsliveshare") {
                    $results.LiveShareInstalled = $true
                }
            }
            
            # Check VS Code settings
            $settingsPath = "$env:APPDATA\Code\User\settings.json"
            if (Test-Path $settingsPath) {
                try {
                    $settings = Get-Content $settingsPath | ConvertFrom-Json
                    $results.Settings = @{
                        connectionMode = $settings.'liveshare.connectionMode'
                        allowGuestDebugControl = $settings.'liveshare.allowGuestDebugControl'
                        allowGuestTaskControl = $settings.'liveshare.allowGuestTaskControl'
                    }
                    
                    if ($settings.'liveshare.connectionMode' -eq 'direct') {
                        $results.LANModeConfigured = $true
                    }
                } catch {
                    $results.Settings = @{ Error = "Could not parse settings" }
                }
            }
            
            # Check firewall rules for Live Share
            $firewallRules = Get-NetFirewallRule -DisplayName "*Live Share*" -ErrorAction SilentlyContinue
            if ($firewallRules) {
                $results.FirewallConfigured = $true
            }
            
            # Test if Live Share ports are accessible
            $testPorts = @(40000, 40050, 40100)
            foreach ($port in $testPorts) {
                $listener = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
                if ($listener) {
                    $results.PortsOpen += $port
                }
            }
            
            return $results
        }
        
        return $result
    } catch {
        Write-Log "? Failed to test $ComputerName : $_" "ERROR"
        return $null
    }
}

function Show-OptimizationReport {
    param([hashtable]$Results)
    
    Write-Host "`n?? Live Share LAN Optimization Report" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Gray
    
    foreach ($pc in $Results.Keys) {
        $data = $Results[$pc]
        Write-Host "`n???  $pc" -ForegroundColor Yellow
        
        if ($data) {
            # Status indicators
            $vsStatus = if ($data.VSCodeInstalled) { "?" } else { "?" }
            $lsStatus = if ($data.LiveShareInstalled) { "?" } else { "?" }
            $lanStatus = if ($data.LANModeConfigured) { "?" } else { "?" }
            $fwStatus = if ($data.FirewallConfigured) { "?" } else { "?" }
            
            Write-Host "   VS Code Installed: $vsStatus"
            Write-Host "   Live Share Installed: $lsStatus"
            Write-Host "   LAN Mode Configured: $lanStatus"
            Write-Host "   Firewall Configured: $fwStatus"
            
            if ($data.Settings -and $data.Settings.connectionMode) {
                Write-Host "   Connection Mode: $($data.Settings.connectionMode)" -ForegroundColor $(if ($data.Settings.connectionMode -eq 'direct') { 'Green' } else { 'Yellow' })
            }
            
            if ($data.PortsOpen.Count -gt 0) {
                Write-Host "   Open Ports: $($data.PortsOpen -join ', ')" -ForegroundColor Green
            }
            
            # Network metrics if available
            if ($Results.NetworkMetrics -and $Results.NetworkMetrics[$pc]) {
                $metrics = $Results.NetworkMetrics[$pc]
                if ($metrics.Average) {
                    $color = if ($metrics.Average -lt 15) { 'Green' } elseif ($metrics.Average -lt 50) { 'Yellow' } else { 'Red' }
                    Write-Host "   Network Latency: $($metrics.Average)ms ($($metrics.Quality))" -ForegroundColor $color
                    
                    if ($ShowDetailedMetrics -and $metrics.Jitter) {
                        Write-Host "   Jitter: $($metrics.Jitter)ms" -ForegroundColor Gray
                        Write-Host "   Range: $($metrics.Minimum)-$($metrics.Maximum)ms" -ForegroundColor Gray
                    }
                }
            }
        } else {
            Write-Host "   ? Unreachable or test failed" -ForegroundColor Red
        }
    }
    
    # Summary
    $totalPCs = $Results.Keys.Count
    $optimized = ($Results.Values | Where-Object { $_ -and $_.LANModeConfigured }).Count
    $reachable = ($Results.Values | Where-Object { $_ -ne $null }).Count
    
    Write-Host "`n?? Summary:" -ForegroundColor Cyan
    Write-Host "   Total PCs: $totalPCs"
    Write-Host "   Reachable: $reachable"
    Write-Host "   LAN Optimized: $optimized"
    
    $optimizationPercentage = if ($reachable -gt 0) { [math]::Round(($optimized / $reachable) * 100, 1) } else { 0 }
    $color = if ($optimizationPercentage -eq 100) { 'Green' } elseif ($optimizationPercentage -gt 50) { 'Yellow' } else { 'Red' }
    Write-Host "   Optimization Level: $optimizationPercentage%" -ForegroundColor $color
}
#endregion

Write-Host "?? Live Share LAN Optimization Tester" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Gray

# Auto-discover PCs if requested
if ($AutoDiscover) {
    Write-Log "?? Auto-discovering PCs..." "INFO"
    $allPCs = Get-FleetGuests -PreferredHosts $TargetPCs -AutoDiscover
    Write-Log "Found $($allPCs.Count) potential target PCs: $($allPCs -join ', ')" "SUCCESS"
} else {
    $allPCs = $TargetPCs
}

# Test each PC
$results = @{}
$networkMetrics = @{}

foreach ($pc in $allPCs) {
    Write-Log "Testing $pc..." "INFO"
    
    # Test network connectivity first
    $pingResult = Test-Connection -ComputerName $pc -Count 2 -Quiet -ErrorAction SilentlyContinue
    if ($pingResult) {
        # Get detailed network metrics
        if (-not $TestOnly) {
            $networkMetrics[$pc] = Measure-GuestLatency -Guests @($pc) -PingCount $PingCount -IncludeJitter
            $networkMetrics[$pc] = $networkMetrics[$pc][$pc]  # Extract the specific PC's metrics
        }
        
        # Test Live Share optimization
        $results[$pc] = Test-LiveShareOptimization -ComputerName $pc
    } else {
        Write-Log "? $pc is unreachable" "ERROR"
        $results[$pc] = $null
    }
}

# Add network metrics to results for reporting
$results.NetworkMetrics = $networkMetrics

# Display results
Show-OptimizationReport -Results $results

# Recommendations
Write-Host "`n?? Recommendations:" -ForegroundColor Cyan
$needsOptimization = $results.Keys | Where-Object { 
    $pc = $results[$_]
    $pc -and (-not $pc.LANModeConfigured -or -not $pc.LiveShareInstalled)
}

if ($needsOptimization.Count -gt 0) {
    Write-Host "   Run fleet deployment to optimize these PCs:" -ForegroundColor Yellow
    Write-Host "   .\scripts\Deploy-LiveShare-Fleet.ps1 -Targets @('$($needsOptimization -join "','")') -InstallLiveShare -OptimizeLAN" -ForegroundColor Gray
}

$highLatencyPCs = $networkMetrics.Keys | Where-Object {
    $metrics = $networkMetrics[$_]
    $metrics.Average -and $metrics.Average -gt 50
}

if ($highLatencyPCs.Count -gt 0) {
    Write-Host "   These PCs have high latency (>50ms):" -ForegroundColor Yellow
    foreach ($pc in $highLatencyPCs) {
        Write-Host "   - $pc : $($networkMetrics[$pc].Average)ms" -ForegroundColor Red
    }
    Write-Host "   Consider checking network infrastructure" -ForegroundColor Gray
}

if ($results.Values | Where-Object { $_ -and $_.LANModeConfigured }) {
    Write-Host "   ? Ready for optimized Live Share collaboration!" -ForegroundColor Green
}