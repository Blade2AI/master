param(
    [string]$NasRoot = "\\dxp4800plus-67ba\ops",
    [string]$WorkspacePath = "",
    [switch]$AutoOpen,
    [int]$RetryAttempts = 5,
    [int]$RetryDelaySec = 10,
    [switch]$ForceLANMode
)

#region Configuration and Setup
$logDir = Join-Path $env:USERPROFILE "LiveShareLogs"
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $logDir "LiveShare_Guest_$timestamp.log"
$linkFile = Join-Path $NasRoot "LiveShareLink.txt"
$statusFile = Join-Path $NasRoot "LiveShareStatus.json"

# Helper function for logging with motto integration
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $time = Get-Date -Format "HH:mm:ss"
    $entry = "[$time] [$Level] $Message"
    Write-Host $entry -ForegroundColor $(switch($Level) { "ERROR" {"Red"} "WARN" {"Yellow"} "SUCCESS" {"Green"} "MOTTO" {"Magenta"} default {"White"} })
    Add-Content -Path $logFile -Value $entry
}

# ———————————————————————————————————————————————————————————————————————————————__
# ?? MOTTO: Join collaboration with kindness
Write-Log "?? In a world you can be anything – be nice." "MOTTO"
Write-Log "?? Joining collaborative C++ development with a kind heart..." "MOTTO"
# ———————————————————————————————————————————————————————————————————————————————__

# Helper function to configure LAN-only mode locally
function Set-LocalLANMode {
    Write-Log "?? Configuring local VS Code for LAN-only mode..." "INFO"
    Write-Log "?? Preparing for direct, heartfelt collaboration..." "MOTTO"
    
    try {
        $settingsPath = "$env:APPDATA\Code\User\settings.json"
        $settingsDir = Split-Path $settingsPath -Parent
        
        # Ensure settings directory exists
        if (!(Test-Path $settingsDir)) {
            New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
        }
        
        # Read existing settings or create new
        if (Test-Path $settingsPath) {
            $json = Get-Content $settingsPath -Raw | ConvertFrom-Json
            if (-not $json) { $json = [PSCustomObject]@{} }
        } else {
            $json = [PSCustomObject]@{}
        }
        
        # Add Live Share settings for LAN-only mode
        $modified = $false
        
        if (-not $json.PSObject.Properties.Name -contains "liveshare.connectionMode") {
            $json | Add-Member -Type NoteProperty -Name "liveshare.connectionMode" -Value "direct" -Force
            $modified = $true
        } elseif ($json."liveshare.connectionMode" -ne "direct") {
            $json."liveshare.connectionMode" = "direct"
            $modified = $true
        }
        
        if (-not $json.PSObject.Properties.Name -contains "liveshare.allowGuestDebugControl") {
            $json | Add-Member -Type NoteProperty -Name "liveshare.allowGuestDebugControl" -Value $true -Force
            $modified = $true
        }
        
        if (-not $json.PSObject.Properties.Name -contains "liveshare.allowGuestTaskControl") {
            $json | Add-Member -Type NoteProperty -Name "liveshare.allowGuestTaskControl" -Value $true -Force
            $modified = $true
        }
        
        if (-not $json.PSObject.Properties.Name -contains "liveshare.guestApprovalRequired") {
            $json | Add-Member -Type NoteProperty -Name "liveshare.guestApprovalRequired" -Value $false -Force
            $modified = $true
        }
        
        # Write settings back if modified
        if ($modified) {
            $json | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
            Write-Log "? LAN-only mode configured successfully with care" "SUCCESS"
        } else {
            Write-Log "? LAN-only mode already configured with thoughtfulness" "SUCCESS"
        }
        
    } catch {
        Write-Log "? Failed to configure LAN-only mode: $_" "ERROR"
        Write-Log "?? Challenges met with patience and understanding" "MOTTO"
    }
}

# Helper function to measure latency to host
function Measure-HostLatency {
    param([string]$HostName)
    
    if (-not $HostName) { return $null }
    
    try {
        Write-Log "?? Measuring latency to host $HostName with care..." "INFO"
        $pingResults = Test-Connection -ComputerName $HostName -Count 4 -ErrorAction SilentlyContinue
        
        if ($pingResults) {
            $avgLatency = ($pingResults | Measure-Object -Property ResponseTime -Average).Average
            $roundedLatency = [math]::Round($avgLatency, 2)
            
            $quality = if ($roundedLatency -lt 5) { "Excellent" } 
                      elseif ($roundedLatency -lt 15) { "Good" } 
                      elseif ($roundedLatency -lt 50) { "Fair" } 
                      else { "Poor" }
            
            Write-Log "?? Host latency: ${roundedLatency}ms ($quality) - connection made with kindness" $(if ($roundedLatency -lt 15) { "SUCCESS" } elseif ($roundedLatency -lt 50) { "WARN" } else { "ERROR" })
            return $roundedLatency
        } else {
            Write-Log "? Host $HostName unreachable - extending patience" "WARN"
            return $null
        }
    } catch {
        Write-Log "? Failed to ping host: $_" "ERROR"
        Write-Log "?? Network challenges met with understanding" "MOTTO"
        return $null
    }
}
#endregion

try {
    Write-Log "?? Starting Live Share guest join process on $env:COMPUTERNAME" "SUCCESS"
    
    # Check NAS connectivity
    if (-not (Test-Path $NasRoot)) {
        Write-Log "? Cannot access NAS at $NasRoot - check network connectivity" "ERROR"
        Write-Log "?? Connection challenges met with patience" "MOTTO"
        exit 1
    }
    
    # Configure LAN-only mode first
    if ($ForceLANMode -or $true) {  # Default to always configure for LAN
        Set-LocalLANMode
    }
    
    # Check if Live Share extension is installed
    $liveShareCheck = & code --list-extensions 2>$null | Where-Object { $_ -match "ms-vsliveshare" }
    if (-not $liveShareCheck) {
        Write-Log "? Live Share extension not found. Installing with care..." "WARN"
        Write-Log "??? Preparing tools for collaborative kindness..." "MOTTO"
        
        try {
            & code --install-extension ms-vsliveshare.vsliveshare --force
            Write-Log "? Live Share extension installed. Please restart VS Code and run this script again." "SUCCESS"
            Write-Log "?? Ready to collaborate with kindness!" "MOTTO"
            exit 0
        } catch {
            Write-Log "? Failed to install Live Share extension: $_" "ERROR"
            exit 1
        }
    }
    
    # Wait for and retrieve the Live Share link
    Write-Log "?? Looking for Live Share session..."
    Write-Log "?? Seeking opportunities for collaborative magic..." "MOTTO"
    
    $link = $null
    $hostInfo = $null
    $attempt = 0
    
    while (-not $link -and $attempt -lt $RetryAttempts) {
        $attempt++
        
        # Check status file first for more info
        if (Test-Path $statusFile) {
            try {
                $status = Get-Content $statusFile | ConvertFrom-Json
                if ($status.Status -eq "Active" -and $status.Link) {
                    $link = $status.Link
                    $hostInfo = $status
                    Write-Log "?? Found active session from status file" "SUCCESS"
                    Write-Log "?? Discovered a kind invitation to collaborate!" "MOTTO"
                    Write-Log "   Host: $($status.Host)"
                    Write-Log "   Started: $($status.Timestamp)"
                    Write-Log "   Connection Mode: $($status.ConnectionMode)"
                    Write-Log "   C++ Standard: $($status.CppStandard)"
                    
                    if ($status.Motto) {
                        Write-Log "   Collaboration Spirit: $($status.Motto)" "MOTTO"
                    }
                    
                    if ($status.Workspace) { Write-Log "   Workspace: $($status.Workspace)" }
                    
                    # Display network performance if available
                    if ($status.GuestLatencies -and $status.GuestLatencies.PSObject.Properties.Name -contains $env:COMPUTERNAME) {
                        $myLatency = $status.GuestLatencies.$($env:COMPUTERNAME)
                        if ($myLatency) {
                            Write-Log "   My Expected Latency: ${myLatency}ms" "INFO"
                        }
                    }
                    break
                }
            } catch {
                Write-Log "Could not parse status file: $_" "WARN"
            }
        }
        
        # Fallback: check link file
        if (Test-Path $linkFile) {
            try {
                $linkContent = Get-Content $linkFile -Raw
                if ($linkContent -match 'https://[^\s]*liveshare[^\s]*') {
                    $link = $linkContent.Trim()
                    Write-Log "?? Found session link from link file" "SUCCESS"
                    break
                }
            } catch {
                Write-Log "Could not read link file: $_" "WARN"
            }
        }
        
        if (-not $link) {
            Write-Log "? No active session found. Waiting with patience... (attempt $attempt/$RetryAttempts)"
            Write-Log "?? Good things come to those who wait with kindness..." "MOTTO"
            Start-Sleep -Seconds $RetryDelaySec
        }
    }
    
    if (-not $link) {
        Write-Log "? No Live Share session found after $RetryAttempts attempts" "ERROR"
        Write-Log "?? Make sure the host has started a session and shared the link" "INFO"
        Write-Log "?? In a world you can be anything – be nice." "MOTTO"
        exit 1
    }
    
    Write-Log "?? Live Share link found: $link" "SUCCESS"
    Write-Log "?? Ready to unwrap the gift of collaboration!" "MOTTO"
    
    # Measure latency to host if we have host info
    $hostLatency = $null
    if ($hostInfo -and $hostInfo.Host) {
        $hostLatency = Measure-HostLatency -HostName $hostInfo.Host
    }
    
    # Determine workspace path if not provided
    if (-not $WorkspacePath) {
        # Try to get from status file
        if ($hostInfo -and $hostInfo.Workspace) {
            $WorkspacePath = $hostInfo.Workspace
            Write-Log "?? Using workspace from host: $WorkspacePath"
        }
        
        # Fallback to current directory
        if (-not $WorkspacePath) {
            $WorkspacePath = Get-Location
            Write-Log "?? Using current directory: $WorkspacePath"
        }
    }
    
    # Open VS Code if requested or if not already running the project
    if ($AutoOpen) {
        Write-Log "?? Opening VS Code with workspace: $WorkspacePath"
        Write-Log "?? Opening doors to collaborative creativity..." "MOTTO"
        
        try {
            Start-Process code -ArgumentList "`"$WorkspacePath`""
            Start-Sleep -Seconds 8  # Give VS Code time to start
        } catch {
            Write-Log "Failed to start VS Code: $_" "WARN"
        }
    }
    
    # Join the Live Share session
    Write-Log "?? Joining Live Share session..."
    Write-Log "?? Stepping into a space of collaborative kindness..." "MOTTO"
    
    try {
        $joinResult = & code --command liveshare.join "$link" 2>&1
        Write-Log "Join command executed: $joinResult"
        
        # Give it a moment to connect
        Start-Sleep -Seconds 5
        
        # Verify connection
        $sessionDetails = & code --command liveshare.showSessionDetails 2>$null
        if ($sessionDetails -and $sessionDetails -notmatch "No active session") {
            Write-Log "? Successfully joined Live Share session!" "SUCCESS"
            Write-Log "?? Welcome to collaborative development with kindness!" "MOTTO"
            Write-Log ""
            Write-Log "?? You now have access to:" "SUCCESS"
            Write-Log "   - Shared code editing (C++14 project) ??"
            Write-Log "   - Shared terminal sessions ???"
            Write-Log "   - Shared debugging ??"
            Write-Log "   - Direct LAN connection (optimized) ??"
            Write-Log "   - A space built with collaborative kindness ??"
            
            if ($hostLatency) {
                Write-Log "   - Network latency: ${hostLatency}ms ?"
            }
            Write-Log ""
            Write-Log "?? Check VS Code status bar for session info"
            Write-Log "?? Use Ctrl+Shift+P > 'Live Share' for more options"
            Write-Log "?? Build C++ with Ctrl+Shift+P > 'Tasks: Run Task' > 'Build: C++ Debug'"
            Write-Log "?? Remember: In a world you can be anything – be nice." "MOTTO"
            
            # Log successful join with metrics and kindness
            $guestStatus = @{
                Guest = $env:COMPUTERNAME
                JoinedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                HostLatency = $hostLatency
                ConnectionMode = "direct"
                Status = "Connected"
                Motto = "In a world you can be anything – be nice."
                CollaborationSpirit = "Joined with kindness"
            }
            
            $guestLogFile = Join-Path $NasRoot "guest-$($env:COMPUTERNAME)-status.json"
            $guestStatus | ConvertTo-Json | Set-Content $guestLogFile -Encoding UTF8
            
        } else {
            Write-Log "??  Join command completed but session status unclear" "WARN"
            Write-Log "Check VS Code manually - you may still be connected"
            Write-Log "?? Challenges met with patience and understanding" "MOTTO"
        }
        
    } catch {
        Write-Log "? Failed to join Live Share session: $_" "ERROR"
        Write-Log "?? Try joining manually: code --command liveshare.join $link" "INFO"
        Write-Log "?? Even in challenges, we maintain our kindness." "MOTTO"
        exit 1
    }
    
} catch {
    Write-Log "? An error occurred: $_" "ERROR"
    Write-Log $_.ScriptStackTrace "ERROR"
    Write-Log "?? In a world you can be anything – be nice." "MOTTO"
} finally {
    Write-Log "?? Guest join process completed with gratitude"
    Write-Log "?? In a world you can be anything – be nice." "MOTTO"
    Write-Log "?? Thank you for choosing collaboration with kindness." "MOTTO"
}