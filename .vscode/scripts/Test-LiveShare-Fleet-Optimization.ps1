<#
Test-LiveShare-Optimization.ps1 - Fleet Network Performance Testing
?? "In a world you can be anything – be nice."

Comprehensive fleet network testing with matrix connectivity analysis
#>

[CmdletBinding()]
param(
    [switch]$AutoDiscover,
    [switch]$ShowDetailedMetrics,
    [int]$PingCount = 4,
    [switch]$MatrixTest
)

# Load fleet configuration
$fleetProfile = Join-Path $PSScriptRoot "fleet-profile.ps1"
if (Test-Path $fleetProfile) {
    . $fleetProfile
} else {
    Write-Warning "Fleet profile not found. Using default configuration."
    $Global:PcList = @('pc-1','pc-2','pc-3','pc-4')
    $Global:Motto = "?? In a world you can be anything – be nice."
    $Global:LogsRoot = Join-Path $env:USERPROFILE "LiveShareLogs"
    $Global:LatencyThresholds = @{ Excellent = 5; Good = 15; Fair = 50 }
}

Write-Host ""
Write-Host $Global:Motto -ForegroundColor Magenta
Write-Host "?? Live Share Fleet Network Optimization Test" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Gray

function Test-PCOptimization {
    param([string]$ComputerName)
    
    Write-Host "?? Testing Live Share optimization on $ComputerName..." -ForegroundColor Cyan
    
    try {
        $result = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $results = @{
                PC = $env:COMPUTERNAME
                VSCodeInstalled = $false
                LiveShareInstalled = $false
                LANModeConfigured = $false
                FirewallConfigured = $false
                PortsOpen = @()
                Settings = @{}
                NetworkOptimized = $false
                Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
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
                        cppStandard = $settings.'C_Cpp.default.cppStandard'
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
            
            # Test Live Share port availability
            $testPorts = @(40000, 40050, 40100)
            foreach ($port in $testPorts) {
                $listener = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
                if ($listener) {
                    $results.PortsOpen += $port
                }
            }
            
            # Check network optimization settings
            try {
                $autotuning = netsh int tcp show global | Select-String "Receive Window Auto-Tuning Level"
                $rss = netsh int tcp show global | Select-String "Receive Side Scaling State"
                
                if ($autotuning -match "normal" -and $rss -match "enabled") {
                    $results.NetworkOptimized = $true
                }
            } catch {
                # Network optimization check failed
            }
            
            return $results
        } -ErrorAction Stop
        
        return $result
    } catch {
        Write-Host "? Failed to test $ComputerName : $_" -ForegroundColor Red
        return @{
            PC = $ComputerName
            Error = $_.Exception.Message
            Reachable = $false
            Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    }
}

function Test-FleetConnectivityMatrix {
    Write-Host "?? Testing fleet connectivity matrix..." -ForegroundColor Cyan
    
    $connectivityMatrix = @{}
    $report = [System.Collections.Generic.List[object]]::new()
    
    foreach ($sourcePC in $Global:PcList) {
        $connectivityMatrix[$sourcePC] = @{}
        
        foreach ($targetPC in $Global:PcList) {
            if ($sourcePC -eq $targetPC) { 
                $connectivityMatrix[$sourcePC][$targetPC] = @{ 
                    Latency = 0
                    Quality = "Self"
                    Success = $true
                }
                continue 
            }
            
            try {
                Write-Host "  Testing $sourcePC ? $targetPC" -ForegroundColor Gray
                
                $pingResult = Invoke-Command -ComputerName $sourcePC -ScriptBlock { 
                    param($target, $count)
                    Test-Connection -ComputerName $target -Count $count -ErrorAction Stop
                } -ArgumentList $targetPC, $PingCount -ErrorAction Stop
                
                $avgLatency = [math]::Round(($pingResult | Measure-Object -Property Latency -Average).Average, 1)
                
                $quality = if ($avgLatency -lt $Global:LatencyThresholds.Excellent) { "Excellent" }
                          elseif ($avgLatency -lt $Global:LatencyThresholds.Good) { "Good" }
                          elseif ($avgLatency -lt $Global:LatencyThresholds.Fair) { "Fair" }
                          else { "Poor" }
                
                $connectivityMatrix[$sourcePC][$targetPC] = @{
                    Latency = $avgLatency
                    Quality = $quality
                    Success = $true
                    PacketLoss = 0
                }
                
                $report.Add([pscustomobject]@{ 
                    From = $sourcePC
                    To = $targetPC
                    LatencyMs = $avgLatency
                    Quality = $quality
                    Success = $true
                })
                
            } catch {
                $connectivityMatrix[$sourcePC][$targetPC] = @{
                    Latency = $null
                    Quality = "Failed"
                    Success = $false
                    Error = $_.Exception.Message
                }
                
                $report.Add([pscustomobject]@{ 
                    From = $sourcePC
                    To = $targetPC
                    LatencyMs = $null
                    Quality = "Failed"
                    Success = $false
                })
                
                Write-Host "  ? $sourcePC ? $targetPC failed" -ForegroundColor Red
            }
        }
    }
    
    return @{
        Matrix = $connectivityMatrix
        Report = $report
    }
}

function Show-OptimizationReport {
    param([hashtable]$Results, [object]$ConnectivityData)
    
    Write-Host "`n?? Live Share Fleet Optimization Report" -ForegroundColor Cyan
    Write-Host $Global:Motto -ForegroundColor Magenta
    Write-Host "=" * 70 -ForegroundColor Gray
    
    # Individual PC optimization status
    foreach ($pc in ($Results.Keys | Sort-Object)) {
        $data = $Results[$pc]
        Write-Host "`n???  $pc" -ForegroundColor Yellow
        
        if ($data.Error) {
            Write-Host "   ? Unreachable: $($data.Error)" -ForegroundColor Red
            continue
        }
        
        # Status indicators with kindness
        $vsStatus = if ($data.VSCodeInstalled) { "?" } else { "?" }
        $lsStatus = if ($data.LiveShareInstalled) { "?" } else { "?" }
        $lanStatus = if ($data.LANModeConfigured) { "?" } else { "?" }
        $fwStatus = if ($data.FirewallConfigured) { "?" } else { "?" }
        $netStatus = if ($data.NetworkOptimized) { "?" } else { "?" }
        
        Write-Host "   VS Code: $vsStatus  Live Share: $lsStatus  LAN Mode: $lanStatus  Firewall: $fwStatus  Network: $netStatus"
        
        if ($data.Settings -and $data.Settings.connectionMode) {
            $modeColor = if ($data.Settings.connectionMode -eq 'direct') { 'Green' } else { 'Yellow' }
            Write-Host "   Connection Mode: $($data.Settings.connectionMode)" -ForegroundColor $modeColor
        }
        
        if ($data.Settings -and $data.Settings.cppStandard) {
            Write-Host "   C++ Standard: $($data.Settings.cppStandard)" -ForegroundColor $(if ($data.Settings.cppStandard -eq 'c++14') { 'Green' } else { 'Yellow' })
        }
        
        if ($data.PortsOpen.Count -gt 0) {
            Write-Host "   Open Ports: $($data.PortsOpen -join ', ')" -ForegroundColor Green
        }
    }
    
    # Fleet connectivity summary
    if ($ConnectivityData) {
        Write-Host "`n?? Fleet Connectivity Matrix:" -ForegroundColor Cyan
        
        $successfulConnections = ($ConnectivityData.Report | Where-Object { $_.Success }).Count
        $totalConnections = $ConnectivityData.Report.Count
        
        Write-Host "   Successful Connections: $successfulConnections/$totalConnections" -ForegroundColor $(if ($successfulConnections -eq $totalConnections) { 'Green' } else { 'Yellow' })
        
        if ($ShowDetailedMetrics) {
            Write-Host "`n   Detailed Connectivity:" -ForegroundColor Gray
            foreach ($connection in ($ConnectivityData.Report | Sort-Object From, To)) {
                if ($connection.Success) {
                    $color = if ($connection.LatencyMs -lt $Global:LatencyThresholds.Good) { 'Green' } 
                            elseif ($connection.LatencyMs -lt $Global:LatencyThresholds.Fair) { 'Yellow' } 
                            else { 'Red' }
                    Write-Host "     $($connection.From) ? $($connection.To): $($connection.LatencyMs)ms ($($connection.Quality))" -ForegroundColor $color
                } else {
                    Write-Host "     $($connection.From) ? $($connection.To): Failed" -ForegroundColor Red
                }
            }
        }
        
        # Average latency calculation
        $successfulLatencies = $ConnectivityData.Report | Where-Object { $_.Success -and $_.LatencyMs } | Select-Object -ExpandProperty LatencyMs
        if ($successfulLatencies.Count -gt 0) {
            $avgFleetLatency = [math]::Round(($successfulLatencies | Measure-Object -Average).Average, 1)
            Write-Host "   Fleet Average Latency: ${avgFleetLatency}ms" -ForegroundColor $(if ($avgFleetLatency -lt $Global:LatencyThresholds.Good) { 'Green' } else { 'Yellow' })
        }
    }
    
    # Summary and recommendations
    $totalPCs = $Results.Keys.Count
    $reachablePCs = ($Results.Values | Where-Object { -not $_.Error }).Count
    $optimizedPCs = ($Results.Values | Where-Object { $_ -and $_.LANModeConfigured }).Count
    
    Write-Host "`n?? Fleet Summary:" -ForegroundColor Cyan
    Write-Host "   Total PCs: $totalPCs"
    Write-Host "   Reachable: $reachablePCs"
    Write-Host "   LAN Optimized: $optimizedPCs"
    
    $optimizationPercentage = if ($reachablePCs -gt 0) { [math]::Round(($optimizedPCs / $reachablePCs) * 100, 1) } else { 0 }
    $color = if ($optimizationPercentage -eq 100) { 'Green' } elseif ($optimizationPercentage -gt 75) { 'Yellow' } else { 'Red' }
    Write-Host "   Optimization Level: $optimizationPercentage%" -ForegroundColor $color
    
    # Recommendations with kindness
    Write-Host "`n?? Recommendations:" -ForegroundColor Cyan
    $needsOptimization = $Results.Keys | Where-Object { 
        $pc = $Results[$_]
        $pc -and -not $pc.Error -and (-not $pc.LANModeConfigured -or -not $pc.LiveShareInstalled)
    }
    
    if ($needsOptimization.Count -gt 0) {
        Write-Host "   Run fleet deployment to optimize these PCs with care:" -ForegroundColor Yellow
        Write-Host "   .\Deploy-LiveShare-Fleet-Production.ps1 -InstallLiveShare -OptimizeLAN" -ForegroundColor Gray
        Write-Host "   Target PCs: $($needsOptimization -join ', ')"
    }
    
    if ($ConnectivityData) {
        $highLatencyConnections = $ConnectivityData.Report | Where-Object { $_.Success -and $_.LatencyMs -gt $Global:LatencyThresholds.Fair }
        if ($highLatencyConnections.Count -gt 0) {
            Write-Host "   These connections have higher latency:" -ForegroundColor Yellow
            foreach ($conn in $highLatencyConnections) {
                Write-Host "   - $($conn.From) ? $($conn.To): $($conn.LatencyMs)ms" -ForegroundColor Red
            }
            Write-Host "   Consider checking network infrastructure with patience" -ForegroundColor Gray
        }
    }
    
    if ($optimizationPercentage -eq 100 -and $reachablePCs -eq $totalPCs) {
        Write-Host "   ? Fleet is fully optimized for collaborative kindness!" -ForegroundColor Green
        Write-Host "   ?? Ready for high-performance Live Share collaboration!" -ForegroundColor Green
    }
}

# Main execution with fleet testing
Write-Host "?? Testing Live Share optimization across fleet..." -ForegroundColor Yellow

# Test each PC's optimization status
$optimizationResults = @{}
foreach ($pc in $Global:PcList) {
    $optimizationResults[$pc] = Test-PCOptimization -ComputerName $pc
}

# Test fleet connectivity matrix if requested
$connectivityData = $null
if ($MatrixTest) {
    $connectivityData = Test-FleetConnectivityMatrix
}

# Display comprehensive report
Show-OptimizationReport -Results $optimizationResults -ConnectivityData $connectivityData

# Save results to fleet logs
$testResults = @{
    TestTimestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Motto = $Global:Motto
    FleetOptimization = $optimizationResults
    ConnectivityMatrix = if ($connectivityData) { $connectivityData.Matrix } else { $null }
    ConnectivityReport = if ($connectivityData) { $connectivityData.Report } else { $null }
    TestParameters = @{
        AutoDiscover = $AutoDiscover
        ShowDetailedMetrics = $ShowDetailedMetrics
        PingCount = $PingCount
        MatrixTest = $MatrixTest
    }
}

$resultsFile = Join-Path $Global:LogsRoot "fleet-optimization-test_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$testResults | ConvertTo-Json -Depth 6 | Set-Content $resultsFile -Encoding UTF8

Write-Host "`n?? Test results saved to: $resultsFile" -ForegroundColor Green
Write-Host $Global:Motto -ForegroundColor Magenta
Write-Host ""