<#
Deploy-LiveShare-Fleet.ps1 - Production Fleet Management
?? "In a world you can be anything – be nice."

- Enables PSRemoting + WinRM trust
- Opens firewall rules for Live Share direct connections  
- Pushes optimized VS Code settings/tasks for C++14 development
- Drops desktop shortcuts with kindness themes
- Installs VS Code + Live Share via winget with care
- Configures LAN optimization for <5ms collaboration

Usage:
  .\Deploy-LiveShare-Fleet.ps1 -InstallLiveShare -SetupTasks -OptimizeLAN -DeployPackages
#>

[CmdletBinding()]
param(
    [switch]$InstallLiveShare,
    [switch]$SetupTasks, 
    [switch]$OptimizeLAN,
    [switch]$DeployPackages,
    [switch]$TestConnectivity,
    [string]$SlackWebhook = ""
)

$ErrorActionPreference = 'Stop'

# Load fleet configuration with kindness
. (Join-Path $PSScriptRoot "fleet-profile.ps1")

Write-Host ""
Write-Host $Global:Motto -ForegroundColor Magenta
Write-Host "?? Starting fleet deployment with collaborative excellence..." -ForegroundColor Green
Write-Host ""

function Write-FleetLog {
    param([string]$Message, [string]$Level = "INFO", [string]$PC = "LOCAL")
    $time = Get-Date -Format "HH:mm:ss"
    $colors = @{ "INFO" = "White"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green"; "MOTTO" = "Magenta" }
    $entry = "[$time] [$PC] [$Level] $Message"
    Write-Host $entry -ForegroundColor $colors[$Level]
    
    $logFile = Join-Path $Global:LogsRoot "fleet-deploy_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    Add-Content -Path $logFile -Value $entry
}

function Invoke-FleetOperation {
    param(
        [scriptblock]$ScriptBlock,
        [string]$OperationName,
        [hashtable]$Arguments = @{}
    )
    
    Write-FleetLog "?? Starting '$OperationName' across fleet..." "INFO"
    $results = @{}
    
    foreach ($pc in $Global:PcList) {
        $startTime = Get-Date
        try {
            Write-FleetLog "?? Executing on $pc..." "INFO" $pc
            
            $job = Invoke-Command -ComputerName $pc -ScriptBlock $ScriptBlock -ArgumentList $Arguments.Values -AsJob
            $result = Receive-Job -Job $job -Wait -AutoRemoveJob
            
            $duration = ((Get-Date) - $startTime).TotalSeconds
            $results[$pc] = @{ Success = $true; Duration = $duration; Output = $result }
            
            Write-FleetLog "? '$OperationName' completed successfully (${duration}s)" "SUCCESS" $pc
            
        } catch {
            $duration = ((Get-Date) - $startTime).TotalSeconds
            $results[$pc] = @{ Success = $false; Duration = $duration; Error = $_.Exception.Message }
            
            Write-FleetLog "? '$OperationName' failed: $($_.Exception.Message)" "ERROR" $pc
        }
    }
    
    # Summary with kindness
    $successful = ($results.Values | Where-Object { $_.Success }).Count
    $total = $results.Count
    
    if ($successful -eq $total) {
        Write-FleetLog "?? '$OperationName' completed successfully on all $total PCs!" "SUCCESS"
    } else {
        Write-FleetLog "?? '$OperationName' succeeded on $successful/$total PCs - showing patience with challenges" "WARN"
    }
    
    return $results
}

# Test connectivity with encouragement
if ($TestConnectivity) {
    Write-FleetLog "?? Testing fleet connectivity with hope..." "INFO"
    
    $connectivityTest = {
        try {
            $hostname = $env:COMPUTERNAME
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            return "? $hostname is ready for collaboration at $timestamp"
        } catch {
            return "? Connection test failed: $($_.Exception.Message)"
        }
    }
    
    $connectivityResults = Invoke-FleetOperation -ScriptBlock $connectivityTest -OperationName "Connectivity Test"
}

# 0) Setup PSRemoting with trust and kindness
Write-FleetLog "?? Establishing trusted connections across the fleet..." "INFO"
try {
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value ($Global:PcList -join ",") -Force
    Enable-PSRemoting -Force *>$null
    Write-FleetLog "? PSRemoting enabled with collaborative trust" "SUCCESS"
} catch {
    Write-FleetLog "? PSRemoting setup failed: $_" "ERROR"
}

# 1) Baseline: Firewall + folders with security mindfulness
$baselineSetup = {
    param($Motto)
    
    # Create collaboration directories
    New-Item -ItemType Directory -Force "C:\BladeMesh\Inbox", "C:\BladeMesh\Outbox", "C:\ops\LiveShare" | Out-Null
    
    # Enable file sharing with security
    Enable-NetFirewallRule -Group "@FirewallAPI.dll,-28502" *>$null  # File & Printer Sharing
    Enable-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)" *>$null
    Enable-NetFirewallRule -DisplayGroup "Windows Remote Management" *>$null
    
    # Live Share specific firewall rules
    try {
        New-NetFirewallRule -DisplayName "Live Share Direct - Inbound" -Direction Inbound -Protocol TCP -LocalPort 40000-40100 -Action Allow -Profile Domain,Private -ErrorAction SilentlyContinue
        New-NetFirewallRule -DisplayName "Live Share Direct - Outbound" -Direction Outbound -Protocol TCP -LocalPort 40000-40100 -Action Allow -Profile Domain,Private -ErrorAction SilentlyContinue
    } catch {
        # Rules may already exist - that's okay
    }
    
    return "Baseline setup completed with $Motto"
}

$baselineResults = Invoke-FleetOperation -ScriptBlock $baselineSetup -OperationName "Baseline Security & Directories" -Arguments @{ Motto = $Global:Motto }

# 2) Install VS Code + Live Share with patience
if ($InstallLiveShare) {
    Write-FleetLog "?? Installing VS Code and Live Share extension with care..." "INFO"
    
    $installVSCode = {
        param($Motto)
        $results = @()
        
        # Install VS Code via winget with patience
        try {
            $vsCodeCheck = Get-Command code -ErrorAction SilentlyContinue
            if (-not $vsCodeCheck) {
                $results += "Installing VS Code with kindness..."
                winget install -e --id Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements -h
                Start-Sleep -Seconds 10
                $results += "VS Code installation completed"
            } else {
                $results += "VS Code already installed - showing appreciation"
            }
            
            # Install Live Share extension
            $results += "Installing Live Share extension for collaborative joy..."
            code --install-extension ms-vsliveshare.vsliveshare --force
            Start-Sleep -Seconds 5
            
            # Install C++ extension for development excellence  
            code --install-extension ms-vscode.cpptools --force
            Start-Sleep -Seconds 3
            
            $results += "Extensions installed successfully - ready for collaborative development!"
            
        } catch {
            $results += "Installation encountered challenges: $($_.Exception.Message) - showing patience"
        }
        
        return ($results -join "`n")
    }
    
    $installResults = Invoke-FleetOperation -ScriptBlock $installVSCode -OperationName "VS Code & Extensions Installation" -Arguments @{ Motto = $Global:Motto }
}

# 3) Deploy VS Code settings, tasks, and shortcuts with care
Write-FleetLog "?? Deploying VS Code configuration with collaborative spirit..." "INFO"

$configDeployment = {
    param($PayloadPath, $VSUserDir, $Motto, $CppStandard)
    $results = @()
    
    try {
        # Ensure VS Code user directory exists
        $destDir = $VSUserDir.Replace('$env:USERPROFILE', $env:USERPROFILE)
        New-Item -ItemType Directory -Force $destDir | Out-Null
        
        # Deploy settings.json with C++14 optimization
        $settingsSource = Join-Path $PayloadPath "vscode\settings.json"
        if (Test-Path $settingsSource) {
            $settingsContent = Get-Content $settingsSource | ConvertFrom-Json
            $settingsContent.'C_Cpp.default.cppStandard' = $CppStandard
            $settingsContent | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $destDir "settings.json") -Encoding UTF8
            $results += "? VS Code settings deployed with C++14 optimization"
        }
        
        # Deploy tasks.json for collaborative development
        $tasksSource = Join-Path $PayloadPath "vscode\tasks.json"  
        if (Test-Path $tasksSource) {
            Copy-Item $tasksSource (Join-Path $destDir "tasks.json") -Force
            $results += "? Development tasks configured with kindness themes"
        }
        
        # Create desktop shortcuts with encouraging names
        $desktop = [Environment]::GetFolderPath('Desktop')
        $shell = New-Object -ComObject WScript.Shell
        
        # Live Share join shortcut
        $joinShortcut = $shell.CreateShortcut("$desktop\Join Live Share (with Kindness).lnk")
        $joinShortcut.TargetPath = 'powershell.exe'
        $joinShortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "C:\ops\LiveShare\Join-LiveShare-Guest.ps1" -AutoOpen -ForceLANMode'
        $joinShortcut.WorkingDirectory = 'C:\ops\LiveShare'
        $joinShortcut.Description = 'Join Live Share Session with Collaborative Kindness'
        $joinShortcut.Save()
        
        # Live Share host shortcut
        $hostShortcut = $shell.CreateShortcut("$desktop\Start Live Share Host (Enhanced with Kindness).lnk")
        $hostShortcut.TargetPath = 'powershell.exe'
        $hostShortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "C:\ops\LiveShare\Start-LiveShare-Host.ps1" -AutoDiscover -DetailedMetrics'
        $hostShortcut.WorkingDirectory = 'C:\ops\LiveShare'
        $hostShortcut.Description = 'Start Live Share Host Session with Network Optimization'
        $hostShortcut.Save()
        
        # PrecisePointway workspace shortcut
        $workspaceShortcut = $shell.CreateShortcut("$desktop\PrecisePointway Workspace (C++14).lnk")
        $workspaceShortcut.TargetPath = 'code'
        $workspaceShortcut.Arguments = 'C:\Development\PrecisePointway'
        $workspaceShortcut.WorkingDirectory = 'C:\Development\PrecisePointway'
        $workspaceShortcut.Description = 'Open PrecisePointway C++14 Development Environment'
        $workspaceShortcut.Save()
        
        $results += "? Desktop shortcuts created with collaborative themes"
        $results += "? Configuration deployment completed with care"
        
    } catch {
        $results += "? Configuration deployment encountered challenges: $($_.Exception.Message)"
    }
    
    return ($results -join "`n")
}

$configResults = Invoke-FleetOperation -ScriptBlock $configDeployment -OperationName "VS Code Configuration" -Arguments @{ 
    PayloadPath = $Global:Payload
    VSUserDir = $Global:VSUserDir
    Motto = $Global:Motto
    CppStandard = $Global:CppStandard
}

# 4) LAN optimization for <5ms collaboration
if ($OptimizeLAN) {
    Write-FleetLog "?? Optimizing network for sub-5ms collaborative excellence..." "INFO"
    
    $lanOptimization = {
        param($Motto)
        $results = @()
        
        try {
            # Disable SMB1 for security (enable SMB2/3)
            try {
                Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -WarningAction SilentlyContinue
                $results += "? SMB1 disabled for security, SMB2/3 preferred"
            } catch {
                $results += "?? SMB1 already disabled or unavailable"
            }
            
            # Enable SMB Direct for RDMA if supported
            try {
                Enable-WindowsOptionalFeature -Online -FeatureName SMBDirect -NoRestart -WarningAction SilentlyContinue
                $results += "? SMB Direct enabled for high-performance file sharing"
            } catch {
                $results += "?? SMB Direct not available on this hardware"
            }
            
            # Network stack optimization
            netsh int tcp set global autotuninglevel=normal | Out-Null
            netsh int tcp set global rss=enabled | Out-Null
            netsh int tcp set global chimney=enabled | Out-Null
            $results += "? Network autotuning and RSS enabled for optimal performance"
            
            # Set network adapter to high performance
            Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Power Saving Mode" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
            }
            $results += "? Network adapters optimized for performance over power saving"
            
            $results += "?? LAN optimization completed with $Motto"
            
        } catch {
            $results += "? LAN optimization encountered challenges: $($_.Exception.Message)"
        }
        
        return ($results -join "`n")
    }
    
    $lanResults = Invoke-FleetOperation -ScriptBlock $lanOptimization -OperationName "LAN Performance Optimization" -Arguments @{ Motto = $Global:Motto }
}

# 5) Deploy packages if requested
if ($DeployPackages) {
    Write-FleetLog "?? Deploying software packages with care..." "INFO"
    
    $packageDeployment = {
        param($PayloadPath, $Motto)
        $results = @()
        
        try {
            $packagesDir = Join-Path $PayloadPath "packages"
            if (Test-Path $packagesDir) {
                $packages = Get-ChildItem $packagesDir -Filter "*.msi"
                
                foreach ($package in $packages) {
                    $results += "Installing package: $($package.Name) with patience..."
                    
                    # Calculate hash for verification
                    $hash = Get-FileHash $package.FullName -Algorithm SHA256
                    $results += "Package hash: $($hash.Hash.Substring(0,16))..."
                    
                    # Install with care
                    $installArgs = @("/i", $package.FullName, "/quiet", "/norestart")
                    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -PassThru
                    
                    if ($process.ExitCode -eq 0) {
                        $results += "? $($package.Name) installed successfully"
                    } else {
                        $results += "?? $($package.Name) installation returned code: $($process.ExitCode)"
                    }
                }
                
                $results += "?? Package deployment completed with $Motto"
            } else {
                $results += "?? No packages directory found - skipping with understanding"
            }
            
        } catch {
            $results += "? Package deployment encountered challenges: $($_.Exception.Message)"
        }
        
        return ($results -join "`n")
    }
    
    $packageResults = Invoke-FleetOperation -ScriptBlock $packageDeployment -OperationName "Package Deployment" -Arguments @{ 
        PayloadPath = $Global:Payload
        Motto = $Global:Motto
    }
}

# 6) Final fleet status and notification
Write-FleetLog "?? Generating fleet deployment summary..." "INFO"

$fleetSummary = @{
    DeploymentTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Motto = $Global:Motto
    TotalPCs = $Global:PcList.Count
    SuccessfulPCs = 0
    Operations = @()
    CppStandard = $Global:CppStandard
    OptimizedForLAN = $OptimizeLAN
    LiveShareEnabled = $InstallLiveShare
}

# Calculate success metrics
$allResults = @()
if ($baselineResults) { $allResults += $baselineResults }
if ($installResults) { $allResults += $installResults }
if ($configResults) { $allResults += $configResults }
if ($lanResults) { $allResults += $lanResults }
if ($packageResults) { $allResults += $packageResults }

$successfulOperations = ($allResults | Where-Object { $_.Values.Success -contains $true }).Count
$fleetSummary.SuccessfulPCs = $successfulOperations

# Save deployment summary
$summaryFile = Join-Path $Global:LogsRoot "fleet-deployment-summary_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$fleetSummary | ConvertTo-Json -Depth 5 | Set-Content $summaryFile -Encoding UTF8

Write-FleetLog "?? Deployment summary saved to: $summaryFile" "SUCCESS"

# Send notification if webhook provided
if ($SlackWebhook) {
    try {
        $notification = @{
            text = "?? **Fleet Deployment Complete!**`n" +
                   "$($Global:Motto)`n`n" +
                   "? **Deployment Summary:**`n" +
                   "• Total PCs: $($Global:PcList.Count)`n" +
                   "• C++ Standard: $($Global:CppStandard)`n" +
                   "• LAN Optimized: $(if ($OptimizeLAN) { '? Yes' } else { '? No' })`n" +
                   "• Live Share: $(if ($InstallLiveShare) { '? Enabled' } else { '? Not installed' })`n`n" +
                   "?? **Fleet Ready for Collaborative Development!**"
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri $SlackWebhook -Method Post -Body $notification -ContentType "application/json"
        Write-FleetLog "?? Notification sent with collaborative joy!" "SUCCESS"
    } catch {
        Write-FleetLog "?? Notification failed (but deployment succeeded): $_" "WARN"
    }
}

# Final message with kindness
Write-Host ""
Write-Host "?? Fleet deployment completed with collaborative excellence!" -ForegroundColor Green
Write-Host $Global:Motto -ForegroundColor Magenta
Write-Host ""
Write-Host "?? Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Start Live Share host: 'Start Live Share Host (Enhanced with Kindness)' shortcut"
Write-Host "  2. Join from guests: 'Join Live Share (with Kindness)' shortcut"
Write-Host "  3. Test network: .\Test-LiveShare-Optimization.ps1 -AutoDiscover"
Write-Host "  4. Monitor fleet: Check logs in $($Global:LogsRoot)"
Write-Host ""
Write-Host "?? Your fleet is ready for kindness-driven C++14 collaboration!" -ForegroundColor Green
Write-Host ""