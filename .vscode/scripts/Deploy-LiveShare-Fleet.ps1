param(
    [string[]]$Targets = @('pc-1','pc-2','pc-3','pc-4'),
    [string]$NasRoot = "\\dxp4800plus-67ba\ops",
    [string]$WorkspaceRepo = "https://github.com/PrecisePointway/master",
    [switch]$InstallLiveShare,
    [switch]$SetupTasks,
    [switch]$OptimizeLAN,
    [switch]$EnableiOSDevelopment
)

$ws = Split-Path -Parent $PSScriptRoot

Write-Host "?? Deploying Live Share setup to fleet..." -ForegroundColor Green

# Ensure NAS structure for Live Share
$liveShareDir = Join-Path $NasRoot 'LiveShare'
New-Item -ItemType Directory -Force -Path $liveShareDir | Out-Null

# Package Live Share scripts
$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$packageName = "liveshare_setup_$timestamp"
$packageDir = Join-Path $NasRoot "Packages\$packageName"
New-Item -ItemType Directory -Force -Path $packageDir | Out-Null

# Copy scripts to package
Write-Host "?? Packaging Live Share scripts..." -ForegroundColor Yellow
Copy-Item -Path (Join-Path $ws 'scripts\Start-LiveShare-Host.ps1') -Destination $packageDir -Force
Copy-Item -Path (Join-Path $ws 'scripts\Join-LiveShare-Guest.ps1') -Destination $packageDir -Force
Copy-Item -Path (Join-Path $ws 'scripts\Start-Collab.ps1') -Destination $packageDir -Force
Copy-Item -Path (Join-Path $ws 'scripts\End-Collab.ps1') -Destination $packageDir -Force

# Copy tasks.json template
$tasksTemplate = Join-Path $ws '.vscode\tasks.json'
if (Test-Path $tasksTemplate) {
    Copy-Item -Path $tasksTemplate -Destination $packageDir -Force
}

# Create VS Code settings template for LAN optimization + iOS development
$vsCodeSettings = @{
    "liveshare.connectionMode" = "direct"
    "liveshare.allowGuestDebugControl" = $true
    "liveshare.allowGuestTaskControl" = $true
    "liveshare.guestApprovalRequired" = $false
    "liveshare.showInStatusBar" = "whileCollaborating"
    "liveshare.focusBehavior" = "prompt"
    "liveshare.joinDebugSessionOption" = "Automatic"
    "C_Cpp.default.cppStandard" = "c++14"
    "C_Cpp.default.intelliSenseMode" = "windows-msvc-x64"
    "files.associations" = @{
        "*.h" = "cpp"
        "*.hpp" = "cpp"
        "*.m" = "objective-c"
        "*.mm" = "objective-cpp"
    }
}

# Add iOS development settings if enabled
if ($EnableiOSDevelopment) {
    Write-Host "?? Adding iOS development capabilities..." -ForegroundColor Cyan
    
    $iOSSettings = @{
        "remote.SSH.remotePlatform" = @{
            "your-mac-hostname" = "macOS"
        }
        "remote.SSH.configFile" = "C:\\Users\\%USERNAME%\\.ssh\\config"
        "ios-debug.iosAppBundleId" = "com.precisepoitway.app"
        "ios-debug.targetBuildDir" = "/path/to/build"
        "files.associations" = @{
            "*.swift" = "swift"
            "*.storyboard" = "xml"
            "*.xib" = "xml"
            "*.plist" = "xml"
        }
    }
    
    # Merge iOS settings
    foreach ($key in $iOSSettings.Keys) {
        $vsCodeSettings[$key] = $iOSSettings[$key]
    }
}

$settingsJson = $vsCodeSettings | ConvertTo-Json -Depth 10
Set-Content -Path (Join-Path $packageDir 'vscode-settings-template.json') -Value $settingsJson -Encoding UTF8

foreach ($target in $Targets) {
    $host = $target.ToLower()
    Write-Host "?? Setting up $host..." -ForegroundColor Cyan
    
    # 1. Deploy Live Share scripts
    Write-Host "  ?? Deploying scripts to $host"
    & "$ws\scripts\Queue-Command.ps1" -Hosts $host -Type deploy -Package $packageDir -Dest 'C:\ops\LiveShare'
    
    # 2. Install VS Code if not present
    $vsCodeInstall = @"
if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    Write-Output "Installing VS Code..."
    try {
        winget install -e --id Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements
        Write-Output "VS Code installed successfully"
    } catch {
        Write-Output "Failed to install VS Code via winget: `$_"
        # Fallback to direct download
        `$url = 'https://code.visualstudio.com/sha/download?build=stable&os=win32-x64'
        `$installer = "`$env:TEMP\VSCodeSetup.exe"
        Invoke-WebRequest -Uri `$url -OutFile `$installer
        Start-Process -FilePath `$installer -ArgumentList '/VERYSILENT', '/NORESTART', '/MERGETASKS=!runcode' -Wait
        Remove-Item `$installer -Force
        Write-Output "VS Code installed via direct download"
    }
} else {
    Write-Output "VS Code already installed"
}
"@
    & "$ws\scripts\Queue-Command.ps1" -Hosts $host -Code $vsCodeInstall | Out-Null
    
    # 3. Install Live Share extension and iOS development extensions if requested
    if ($InstallLiveShare) {
        Write-Host "  ?? Installing Live Share and iOS extensions on $host"
        
        $extensionInstall = @"
# Wait for VS Code installation to complete
Start-Sleep -Seconds 10

# Install Live Share extension
Write-Output "Installing Live Share extension..."
code --install-extension ms-vsliveshare.vsliveshare --force
Start-Sleep -Seconds 5
"@
        
        if ($EnableiOSDevelopment) {
            $iOSExtensions = @"
# Install iOS development extensions
Write-Output "Installing iOS development extensions..."
code --install-extension ms-vscode-remote.remote-ssh --force
code --install-extension ms-vscode.remote-explorer --force
code --install-extension vadimcn.vscode-lldb --force
code --install-extension ms-vscode.cpptools --force
code --install-extension swift.swiftlang --force
Start-Sleep -Seconds 5
"@
            $extensionInstall += $iOSExtensions
        }
        
        $extensionInstall += @"
# Configure VS Code settings for LAN optimization and iOS
Write-Output "Configuring VS Code for LAN optimization and iOS development..."
`$settingsPath = "`$env:APPDATA\Code\User\settings.json"
`$settingsDir = Split-Path `$settingsPath -Parent

# Ensure settings directory exists
if (!(Test-Path `$settingsDir)) {
    New-Item -ItemType Directory -Path `$settingsDir -Force | Out-Null
}

# Read template settings
`$templatePath = 'C:\ops\LiveShare\vscode-settings-template.json'
if (Test-Path `$templatePath) {
    `$templateSettings = Get-Content `$templatePath | ConvertFrom-Json
    
    # Read existing settings or create new
    if (Test-Path `$settingsPath) {
        try {
            `$existingSettings = Get-Content `$settingsPath -Raw | ConvertFrom-Json
            if (-not `$existingSettings) { `$existingSettings = [PSCustomObject]@{} }
        } catch {
            `$existingSettings = [PSCustomObject]@{}
        }
    } else {
        `$existingSettings = [PSCustomObject]@{}
    }
    
    # Merge template settings with existing settings
    foreach (`$prop in `$templateSettings.PSObject.Properties) {
        if (-not `$existingSettings.PSObject.Properties.Name -contains `$prop.Name) {
            `$existingSettings | Add-Member -Type NoteProperty -Name `$prop.Name -Value `$prop.Value -Force
        } else {
            `$existingSettings.`$(`$prop.Name) = `$prop.Value
        }
    }
    
    # Write merged settings back
    `$existingSettings | ConvertTo-Json -Depth 10 | Set-Content `$settingsPath -Encoding UTF8
    Write-Output "VS Code settings configured for Live Share LAN optimization and iOS development"
}

Write-Output "Live Share and iOS development extensions installed and configured"
"@
        & "$ws\scripts\Queue-Command.ps1" -Hosts $host -Code $extensionInstall | Out-Null
    }
    
    # 4. Clone/update repository
    Write-Host "  ?? Setting up repository on $host"
    $repoSetup = @"
`$repoDir = 'C:\Development\PrecisePointway'
if (-not (Test-Path `$repoDir)) {
    New-Item -ItemType Directory -Force -Path (Split-Path `$repoDir) | Out-Null
    git clone $WorkspaceRepo `$repoDir
    Write-Output "Repository cloned to `$repoDir"
} else {
    Set-Location `$repoDir
    git pull
    Write-Output "Repository updated at `$repoDir"
}
"@
    & "$ws\scripts\Queue-Command.ps1" -Hosts $host -Code $repoSetup | Out-Null
    
    # 5. Setup workspace tasks if requested
    if ($SetupTasks) {
        Write-Host "  ??  Setting up VS Code tasks on $host"
        $taskSetup = @"
`$repoDir = 'C:\Development\PrecisePointway'
`$vscodeDir = Join-Path `$repoDir '.vscode'
New-Item -ItemType Directory -Force -Path `$vscodeDir | Out-Null
Copy-Item -Path 'C:\ops\LiveShare\tasks.json' -Destination `$vscodeDir -Force
Write-Output "VS Code tasks configured"
"@
        & "$ws\scripts\Queue-Command.ps1" -Hosts $host -Code $taskSetup | Out-Null
    }
    
    # 6. Create convenience shortcuts with iOS capabilities
    Write-Host "  ?? Creating optimized shortcuts on $host"
    $shortcutSetup = @"
`$desktop = [Environment]::GetFolderPath('Desktop')
`$repoDir = 'C:\Development\PrecisePointway'

# Create desktop shortcut for opening workspace
`$shell = New-Object -ComObject WScript.Shell
`$shortcut = `$shell.CreateShortcut("`$desktop\PrecisePointway Workspace.lnk")
`$shortcut.TargetPath = 'code'
`$shortcut.Arguments = "`$repoDir"
`$shortcut.WorkingDirectory = `$repoDir
`$shortcut.IconLocation = 'code.exe,0'
`$shortcut.Description = 'Open PrecisePointway in VS Code'
`$shortcut.Save()

# Create shortcut for joining Live Share with LAN optimization
`$joinShortcut = `$shell.CreateShortcut("`$desktop\Join Live Share (LAN Optimized).lnk")
`$joinShortcut.TargetPath = 'powershell.exe'
`$joinShortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "C:\ops\LiveShare\Join-LiveShare-Guest.ps1" -AutoOpen -ForceLANMode'
`$joinShortcut.WorkingDirectory = 'C:\ops\LiveShare'
`$joinShortcut.Description = 'Join Live Share Session (LAN Optimized)'
`$joinShortcut.Save()

# Create shortcut for host startup (for the designated host PC)
`$hostShortcut = `$shell.CreateShortcut("`$desktop\Start Live Share Host (LAN Optimized).lnk")
`$hostShortcut.TargetPath = 'powershell.exe'
`$hostShortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "C:\ops\LiveShare\Start-LiveShare-Host.ps1" -AutoNotify'
`$hostShortcut.WorkingDirectory = 'C:\ops\LiveShare'
`$hostShortcut.Description = 'Start Live Share Host Session (LAN Optimized)'
`$hostShortcut.Save()
"@

    if ($EnableiOSDevelopment) {
        $iOSShortcuts = @"

# Create shortcut for connecting to Mac for iOS development
`$macShortcut = `$shell.CreateShortcut("`$desktop\Connect to Mac for iOS.lnk")
`$macShortcut.TargetPath = 'code'
`$macShortcut.Arguments = '--command "remote-ssh.connect" your-mac-hostname'
`$macShortcut.WorkingDirectory = 'C:\'
`$macShortcut.Description = 'Connect to Mac for iOS Development'
`$macShortcut.Save()
"@
        $shortcutSetup += $iOSShortcuts
    }
    
    $shortcutSetup += @"

Write-Output "Desktop shortcuts created with LAN optimization$(if ($EnableiOSDevelopment) { " and iOS capabilities" })"
"@
    
    & "$ws\scripts\Queue-Command.ps1" -Hosts $host -Code $shortcutSetup | Out-Null
    
    # 7. Network optimization for Live Share (Windows Firewall rules)
    if ($OptimizeLAN) {
        Write-Host "  ?? Configuring firewall rules for Live Share on $host"
        $firewallSetup = @"
# Allow VS Code and Live Share through Windows Firewall
Write-Output "Configuring firewall rules for Live Share..."

# Allow VS Code
try {
    New-NetFirewallRule -DisplayName "VS Code" -Direction Inbound -Program "`$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" -Action Allow -Profile Domain,Private -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "VS Code" -Direction Outbound -Program "`$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" -Action Allow -Profile Domain,Private -ErrorAction SilentlyContinue
} catch {
    Write-Output "VS Code firewall rules may already exist"
}

# Allow port range for Live Share direct connections (TCP 40000-40100)
try {
    New-NetFirewallRule -DisplayName "Live Share Direct Connection" -Direction Inbound -Protocol TCP -LocalPort 40000-40100 -Action Allow -Profile Domain,Private -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Live Share Direct Connection" -Direction Outbound -Protocol TCP -LocalPort 40000-40100 -Action Allow -Profile Domain,Private -ErrorAction SilentlyContinue
} catch {
    Write-Output "Live Share firewall rules may already exist"
}

Write-Output "Firewall rules configured for Live Share LAN optimization"
"@
        & "$ws\scripts\Queue-Command.ps1" -Hosts $host -Code $firewallSetup | Out-Null
    }
}

# Create an enhanced status dashboard script
$dashboardScript = @"
param([switch]`$Continuous, [switch]`$ShowLatency, [switch]`$ShowiOSStatus)

do {
    Clear-Host
    Write-Host "?? Live Share Fleet Status$(if (`$ShowiOSStatus) { " + iOS Development" }) - `$((Get-Date).ToString('HH:mm:ss'))" -ForegroundColor Green
    Write-Host "=" * 80
    
    `$nasRoot = '$NasRoot'
    `$statusFile = Join-Path `$nasRoot 'LiveShareStatus.json'
    `$linkFile = Join-Path `$nasRoot 'LiveShareLink.txt'
    
    if (Test-Path `$statusFile) {
        try {
            `$status = Get-Content `$statusFile | ConvertFrom-Json
            Write-Host "?? Session Status: " -NoNewline
            switch (`$status.Status) {
                'Active' { Write-Host `$status.Status -ForegroundColor Green }
                'Stopped' { Write-Host `$status.Status -ForegroundColor Red }
                default { Write-Host `$status.Status -ForegroundColor Yellow }
            }
            Write-Host "???  Host: `$(`$status.Host)"
            Write-Host "? Updated: `$(`$status.Timestamp)"
            Write-Host "?? Connection Mode: `$(`$status.ConnectionMode)" -ForegroundColor Green
            if (`$status.CppStandard) { Write-Host "??  C++ Standard: `$(`$status.CppStandard)" }
            if (`$status.Workspace) { Write-Host "?? Workspace: `$(`$status.Workspace)" }
            if (`$status.Link) { Write-Host "?? Link: `$(`$status.Link)" }
            
            # Display network latencies if available
            if (`$ShowLatency -and `$status.GuestLatencies) {
                Write-Host ""
                Write-Host "?? Network Latencies:" -ForegroundColor Cyan
                foreach (`$guest in `$status.GuestLatencies.PSObject.Properties) {
                    `$latency = `$guest.Value
                    if (`$latency) {
                        `$quality = if (`$latency -lt 5) { "Excellent" } 
                                   elseif (`$latency -lt 15) { "Good" } 
                                   elseif (`$latency -lt 50) { "Fair" } 
                                   else { "Poor" }
                        `$color = if (`$latency -lt 15) { "Green" } elseif (`$latency -lt 50) { "Yellow" } else { "Red" }
                        Write-Host "   `$(`$guest.Name): `${latency}ms (`$quality)" -ForegroundColor `$color
                    } else {
                        Write-Host "   `$(`$guest.Name): Unreachable" -ForegroundColor Red
                    }
                }
            }
        } catch {
            Write-Host "? Could not parse status file" -ForegroundColor Red
        }
    } else {
        Write-Host "?? No active session found" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "?? Fleet Targets: $($Targets -join ', ')"
    Write-Host "?? NAS Root: `$nasRoot"
    Write-Host "?? LAN Optimized: ?$(if ($EnableiOSDevelopment) { " | ?? iOS Ready: ?" })" -ForegroundColor Green
    
    # Check for guest status files
    `$guestFiles = Get-ChildItem -Path `$nasRoot -Filter "guest-*-status.json" -ErrorAction SilentlyContinue
    if (`$guestFiles) {
        Write-Host ""
        Write-Host "?? Connected Guests:" -ForegroundColor Cyan
        foreach (`$guestFile in `$guestFiles) {
            try {
                `$guestStatus = Get-Content `$guestFile.FullName | ConvertFrom-Json
                `$guestName = `$guestStatus.Guest
                `$joinTime = `$guestStatus.JoinedAt
                `$latency = `$guestStatus.HostLatency
                Write-Host "   `$guestName - Joined: `$joinTime" -ForegroundColor Green
                if (`$latency) {
                    Write-Host "     ?? Latency: `${latency}ms" -ForegroundColor Gray
                }
            } catch {
                Write-Host "   `$(`$guestFile.BaseName) - Status unclear" -ForegroundColor Yellow
            }
        }
    }
    
    if (`$Continuous) {
        Write-Host ""
        Write-Host "Press Ctrl+C to stop monitoring..."
        Start-Sleep -Seconds 10
    }
} while (`$Continuous)
"@

Set-Content -Path (Join-Path $packageDir 'Show-LiveShareStatus.ps1') -Value $dashboardScript -Encoding UTF8

Write-Host ""
Write-Host "? Live Share fleet deployment completed!" -ForegroundColor Green
Write-Host "?? Package: $packageName"
Write-Host "?? LAN Optimization: $(if ($OptimizeLAN -or $InstallLiveShare) { '? Enabled' } else { '??  Use -OptimizeLAN flag for full optimization' })"
if ($EnableiOSDevelopment) {
    Write-Host "?? iOS Development: ? Enabled" -ForegroundColor Green
    Write-Host ""
    Write-Host "?? iOS Development Setup:"
    Write-Host "  1. Configure SSH connection to your Mac"
    Write-Host "  2. Install Xcode on your Mac"
    Write-Host "  3. Use 'Connect to Mac for iOS' desktop shortcut"
    Write-Host "  4. Open iOS project via VS Code Remote-SSH"
}
Write-Host ""
Write-Host "?? Next Steps:"
Write-Host "  1. On the HOST PC: Run 'LiveShare: Start Host Session' task"
Write-Host "  2. On GUEST PCs: Run 'LiveShare: Join Session' task or use desktop shortcut"
Write-Host "  3. Monitor status with: PowerShell $packageDir\Show-LiveShareStatus.ps1 -Continuous -ShowLatency$(if ($EnableiOSDevelopment) { " -ShowiOSStatus" })"
Write-Host ""
Write-Host "?? Available VS Code Tasks:"
Write-Host "  - LiveShare: Start Host Session (LAN Optimized)"
Write-Host "  - LiveShare: Join Session (LAN Optimized)"
Write-Host "  - LiveShare: Check Session Status"
Write-Host "  - Build: C++ Debug/Release (with C++14 standard)"
if ($EnableiOSDevelopment) {
    Write-Host "  - Connect to Mac for iOS Development"
    Write-Host "  - iOS: Build and Debug"
}
Write-Host ""
Write-Host "?? Performance Features:"
Write-Host "  - Direct LAN connections (no relay servers)"
Write-Host "  - Real-time latency monitoring"
Write-Host "  - Optimized firewall rules"
Write-Host "  - C++14 development environment"
if ($EnableiOSDevelopment) {
    Write-Host "  - iOS development via Mac remote connection"
    Write-Host "  - Swift and Objective-C support"
}