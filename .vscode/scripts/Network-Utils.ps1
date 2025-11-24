# Helper function to discover guest PCs dynamically
function Get-FleetGuests {
    param(
        [string[]]$PreferredHosts = @('pc-1','pc-2','pc-3'),
        [switch]$AutoDiscover
    )
    
    $discoveredGuests = @()
    
    if ($AutoDiscover) {
        Write-Log "?? Auto-discovering guest PCs on network..." "INFO"
        try {
            # Try to discover PCs in the same subnet
            $localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq 'Dhcp' -or $_.PrefixOrigin -eq 'Manual' } | Select-Object -First 1).IPAddress
            $subnet = $localIP.Substring(0, $localIP.LastIndexOf('.'))
            
            # Quick ping sweep for common PC naming patterns
            $potentialGuests = @()
            foreach ($i in 1..10) {
                $potentialGuests += "pc-$i"
                $potentialGuests += "dev-$i"
                $potentialGuests += "workstation-$i"
            }
            
            foreach ($guest in $potentialGuests) {
                if (Test-Connection -ComputerName $guest -Count 1 -Quiet -ErrorAction SilentlyContinue) {
                    $discoveredGuests += $guest
                    Write-Log "  ? Discovered: $guest" "SUCCESS"
                }
            }
        } catch {
            Write-Log "Auto-discovery failed, using preferred hosts: $_" "WARN"
        }
    }
    
    # Fall back to preferred hosts or combine with discovered
    if ($discoveredGuests.Count -eq 0) {
        return $PreferredHosts
    } else {
        # Combine and deduplicate
        $allGuests = ($discoveredGuests + $PreferredHosts) | Sort-Object -Unique
        return $allGuests
    }
}

# Enhanced latency measurement with more detailed metrics
function Measure-GuestLatency {
    param(
        [string[]]$Guests,
        [int]$PingCount = 4,
        [switch]$IncludeJitter
    )
    
    Write-Log "?? Measuring network performance to guest PCs..." "INFO"
    $networkMetrics = @{}
    
    foreach ($guestHost in $Guests) {
        try {
            Write-Log "  ?? Testing $guestHost"
            $pingResults = Test-Connection -ComputerName $guestHost -Count $PingCount -ErrorAction SilentlyContinue
            
            if ($pingResults) {
                $responseTimes = $pingResults | ForEach-Object { $_.ResponseTime }
                $avgLatency = ($responseTimes | Measure-Object -Average).Average
                $minLatency = ($responseTimes | Measure-Object -Minimum).Minimum
                $maxLatency = ($responseTimes | Measure-Object -Maximum).Maximum
                
                $metrics = @{
                    Average = [math]::Round($avgLatency, 2)
                    Minimum = $minLatency
                    Maximum = $maxLatency
                    PacketLoss = 0
                    Quality = ""
                    Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                }
                
                if ($IncludeJitter -and $responseTimes.Count -gt 1) {
                    $jitter = 0
                    for ($i = 1; $i -lt $responseTimes.Count; $i++) {
                        $jitter += [math]::Abs($responseTimes[$i] - $responseTimes[$i-1])
                    }
                    $metrics.Jitter = [math]::Round($jitter / ($responseTimes.Count - 1), 2)
                }
                
                # Determine quality based on average latency and jitter
                $quality = if ($avgLatency -lt 5) { "Excellent" } 
                          elseif ($avgLatency -lt 15) { "Good" } 
                          elseif ($avgLatency -lt 50) { "Fair" } 
                          else { "Poor" }
                
                if ($metrics.Jitter -and $metrics.Jitter -gt 10) {
                    $quality += " (High Jitter)"
                }
                
                $metrics.Quality = $quality
                $networkMetrics[$guestHost] = $metrics
                
                Write-Log "  ?? $guestHost : ${avgLatency}ms avg, ${minLatency}-${maxLatency}ms range ($quality)" "SUCCESS"
            } else {
                $networkMetrics[$guestHost] = @{
                    Average = $null
                    PacketLoss = 100
                    Quality = "Unreachable"
                    Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                }
                Write-Log "  ? $guestHost : Unreachable" "WARN"
            }
        } catch {
            $networkMetrics[$guestHost] = @{
                Average = $null
                PacketLoss = 100
                Quality = "Error"
                Error = $_.Exception.Message
                Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            Write-Log "  ? Failed to test $guestHost : $_" "ERROR"
        }
    }
    
    return $networkMetrics
}