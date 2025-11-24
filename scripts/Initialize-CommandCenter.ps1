# Initialize BACKDROP3 as PrecisePointway Command Center
# ===========================================================
# Configures this PC as the central coordinator for 5-PC fleet
#
# Requirements:
# - Windows 11 with Hyper-V
# - Static IP on 10Gb network (192.168.0.10)
# - Access to QNAP NAS (\\dxp4800plus-67ba\ops)
# - Visual Studio Code with Live Share
#
# Author: Andy Jones
# Date: 2025-11-19

param(
    [string]$Role = "Coordinator",  # Options: Coordinator, Host
    [string[]]$FleetPCs = @('pc-1','pc-2','pc-3','pc-4'),
    [string]$NasRoot = "\\dxp4800plus-67ba\ops",
    [string]$LocalOpsDir = "C:\PrecisePointway",
    [switch]$SkipNasCheck,
    [switch]$InstallVSCodeExtensions,
    [switch]$DeployToFleet
)

$ErrorActionPreference = "Stop"

Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "  BACKDROP3 PrecisePointway Command Center Initialization" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# STEP 1: System Validation
# ==============================================================================

Write-Host "[1/8] Validating system requirements..." -ForegroundColor Yellow

# Check OS
$os = Get-CimInstance Win32_OperatingSystem
if ($os.Caption -notmatch "Windows 11") {
    Write-Warning "Expected Windows 11, found: $($os.Caption)"
}

# Check Hyper-V
$hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
if ($hyperv.State -ne "Enabled") {
    Write-Warning "Hyper-V not enabled. Required for advanced networking."
}

# Check static IP
$ethernet = Get-NetIPAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4 -ErrorAction SilentlyContinue
if ($ethernet -and $ethernet.IPAddress -eq "192.168.0.10") {
    Write-Host "  ✓ Static IP confirmed: 192.168.0.10" -ForegroundColor Green
} else {
    Write-Warning "Static IP not set to 192.168.0.10. Current: $($ethernet.IPAddress)"
}

# Check processor
$cpu = Get-CimInstance Win32_Processor
Write-Host "  ✓ CPU: $($cpu.Name) ($($cpu.NumberOfLogicalProcessors) logical cores)" -ForegroundColor Green

Write-Host ""

# ==============================================================================
# STEP 2: NAS Connectivity Test
# ==============================================================================

Write-Host "[2/8] Testing NAS connectivity..." -ForegroundColor Yellow

if (-not $SkipNasCheck) {
    $nasHost = ($NasRoot -split '\\')[2]
    $pingResult = Test-Connection -ComputerName $nasHost -Count 2 -Quiet

    if ($pingResult) {
        $latency = (Test-Connection -ComputerName $nasHost -Count 4 | Measure-Object -Property ResponseTime -Average).Average
        Write-Host "  ✓ NAS reachable: $nasHost (avg latency: $([math]::Round($latency, 1))ms)" -ForegroundColor Green

        if ($latency -lt 5) {
            Write-Host "    Network quality: EXCELLENT (direct 10Gb connection)" -ForegroundColor Green
        } elseif ($latency -lt 15) {
            Write-Host "    Network quality: GOOD" -ForegroundColor Yellow
        } else {
            Write-Warning "    Network latency high (>${latency}ms). Check 10Gb switch."
        }
    } else {
        throw "Cannot reach NAS at $nasHost. Check network configuration."
    }

    # Test NAS paths
    $testPaths = @(
        (Join-Path $NasRoot 'Queue'),
        (Join-Path $NasRoot 'Packages'),
        (Join-Path $NasRoot 'Config'),
        (Join-Path $NasRoot 'logs')
    )

    foreach ($path in $testPaths) {
        if (Test-Path $path) {
            Write-Host "  ✓ NAS path exists: $path" -ForegroundColor Green
        } else {
            Write-Host "  ! Creating NAS path: $path" -ForegroundColor Yellow
            New-Item -ItemType Directory -Force -Path $path | Out-Null
        }
    }
}

Write-Host ""

# ==============================================================================
# STEP 3: Create Local Operations Directory
# ==============================================================================

Write-Host "[3/8] Setting up local operations directory..." -ForegroundColor Yellow

if (-not (Test-Path $LocalOpsDir)) {
    New-Item -ItemType Directory -Force -Path $LocalOpsDir | Out-Null
    Write-Host "  ✓ Created: $LocalOpsDir" -ForegroundColor Green
} else {
    Write-Host "  ✓ Exists: $LocalOpsDir" -ForegroundColor Green
}

# Create subdirectories
$localDirs = @('scripts', 'config', 'logs', 'data', 'vault')
foreach ($dir in $localDirs) {
    $fullPath = Join-Path $LocalOpsDir $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Force -Path $fullPath | Out-Null
    }
}

Write-Host "  ✓ Local directory structure ready" -ForegroundColor Green
Write-Host ""

# ==============================================================================
# STEP 4: Copy Fleet Scripts to Local Ops
# ==============================================================================

Write-Host "[4/8] Installing fleet coordination scripts..." -ForegroundColor Yellow

$scriptSource = Join-Path $PSScriptRoot '.'
$scriptDest = Join-Path $LocalOpsDir 'scripts'

$coreScripts = @(
    'FleetBootstrap.ps1',
    'FleetPullAgent.ps1',
    'Queue-Command.ps1',
    'LiveShare-Status.ps1',
    'LiveShare-QuickJoin.ps1',
    'Review-VSCode-Fleet.ps1',
    'Ship-Logs.ps1',
    'Recover-VSCode-PC.ps1',
    'Full-AutoRun.ps1',
    'master_closeout.ps1',
    'Notify-Module.psm1'
)

foreach ($script in $coreScripts) {
    $src = Join-Path $scriptSource $script
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $scriptDest -Force
        Write-Host "  ✓ Installed: $script" -ForegroundColor Green
    } else {
        Write-Warning "  ! Missing: $script"
    }
}

Write-Host ""

# ==============================================================================
# STEP 5: Configure Command Center Role
# ==============================================================================

Write-Host "[5/8] Configuring command center role: $Role..." -ForegroundColor Yellow

$configFile = Join-Path $LocalOpsDir 'config\command-center.json'
$config = @{
    hostname = $env:COMPUTERNAME
    role = $Role
    static_ip = "192.168.0.10"
    fleet_pcs = $FleetPCs
    nas_root = $NasRoot
    local_ops = $LocalOpsDir
    initialized = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    network_quality_target = "< 5ms latency"
}

$config | ConvertTo-Json -Depth 5 | Set-Content -Path $configFile -Encoding UTF8
Write-Host "  ✓ Config saved: $configFile" -ForegroundColor Green

# Create fleet inventory
$fleetInventory = @{
    command_center = @{
        hostname = $env:COMPUTERNAME
        ip = "192.168.0.10"
        role = $Role
        cpu = $cpu.Name
        cores = $cpu.NumberOfLogicalProcessors
        ram_gb = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
    }
    fleet_nodes = @()
}

foreach ($pc in $FleetPCs) {
    $fleetInventory.fleet_nodes += @{
        hostname = $pc
        status = "pending_discovery"
        last_seen = $null
    }
}

$inventoryFile = Join-Path $LocalOpsDir 'config\fleet-inventory.json'
$fleetInventory | ConvertTo-Json -Depth 5 | Set-Content -Path $inventoryFile -Encoding UTF8
Write-Host "  ✓ Fleet inventory: $inventoryFile" -ForegroundColor Green

Write-Host ""

# ==============================================================================
# STEP 6: Visual Studio Code Extensions (Optional)
# ==============================================================================

if ($InstallVSCodeExtensions) {
    Write-Host "[6/8] Installing VS Code extensions..." -ForegroundColor Yellow

    $extensions = @(
        'ms-vsliveshare.vsliveshare',
        'ms-vscode.cpptools',
        'ms-vscode.powershell',
        'GitHub.copilot'
    )

    foreach ($ext in $extensions) {
        try {
            code --install-extension $ext --force 2>&1 | Out-Null
            Write-Host "  ✓ Installed: $ext" -ForegroundColor Green
        } catch {
            Write-Warning "  ! Failed to install: $ext"
        }
    }
    Write-Host ""
} else {
    Write-Host "[6/8] Skipping VS Code extensions (use -InstallVSCodeExtensions)" -ForegroundColor Gray
    Write-Host ""
}

# ==============================================================================
# STEP 7: Network Discovery (Test Connectivity to Fleet)
# ==============================================================================

Write-Host "[7/8] Discovering fleet PCs on network..." -ForegroundColor Yellow

$discovered = @()
foreach ($pc in $FleetPCs) {
    Write-Host "  Testing: $pc..." -NoNewline

    $pingResult = Test-Connection -ComputerName $pc -Count 1 -Quiet -ErrorAction SilentlyContinue

    if ($pingResult) {
        $latency = (Test-Connection -ComputerName $pc -Count 2 -ErrorAction SilentlyContinue |
                    Measure-Object -Property ResponseTime -Average).Average

        if ($latency) {
            $latencyRounded = [math]::Round($latency, 1)
            Write-Host " ONLINE ($latencyRounded ms)" -ForegroundColor Green
            $discovered += @{
                hostname = $pc
                status = "online"
                latency_ms = $latencyRounded
            }
        } else {
            Write-Host " ONLINE (latency unknown)" -ForegroundColor Yellow
            $discovered += @{
                hostname = $pc
                status = "online"
                latency_ms = $null
            }
        }
    } else {
        Write-Host " OFFLINE" -ForegroundColor Red
        $discovered += @{
            hostname = $pc
            status = "offline"
            latency_ms = $null
        }
    }
}

$discoveryFile = Join-Path $LocalOpsDir 'data\network-discovery.json'
$discovered | ConvertTo-Json | Set-Content -Path $discoveryFile -Encoding UTF8

Write-Host ""

# ==============================================================================
# STEP 8: Deploy to Fleet (Optional)
# ==============================================================================

if ($DeployToFleet) {
    Write-Host "[8/8] Deploying fleet automation..." -ForegroundColor Yellow

    $bootstrap = Join-Path $scriptDest 'FleetBootstrap.ps1'
    if (Test-Path $bootstrap) {
        $onlineNodes = ($discovered | Where-Object { $_.status -eq "online" }).hostname

        if ($onlineNodes.Count -gt 0) {
            Write-Host "  Deploying to online nodes: $($onlineNodes -join ', ')" -ForegroundColor Yellow
            & $bootstrap -Targets $onlineNodes -NasRoot $NasRoot
        } else {
            Write-Warning "  No online nodes detected. Skipping fleet deployment."
        }
    } else {
        Write-Warning "  FleetBootstrap.ps1 not found. Cannot deploy."
    }
    Write-Host ""
} else {
    Write-Host "[8/8] Skipping fleet deployment (use -DeployToFleet)" -ForegroundColor Gray
    Write-Host ""
}

# ==============================================================================
# Summary
# ==============================================================================

Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "  Command Center Initialization Complete!" -ForegroundColor Green
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration Summary:" -ForegroundColor Yellow
Write-Host "  Role: $Role"
Write-Host "  Hostname: $env:COMPUTERNAME"
Write-Host "  IP: 192.168.0.10"
Write-Host "  Fleet Size: $($FleetPCs.Count) PCs"
Write-Host "  Online Nodes: $($discovered | Where-Object { $_.status -eq 'online' } | Measure-Object | Select-Object -ExpandProperty Count)"
Write-Host "  Local Ops: $LocalOpsDir"
Write-Host "  NAS Root: $NasRoot"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review fleet inventory: $inventoryFile"
Write-Host "  2. Check network discovery: $discoveryFile"
Write-Host "  3. (Optional) Deploy to fleet: .\FleetBootstrap.ps1 -Targets pc-1,pc-2,pc-3,pc-4"
Write-Host "  4. Configure Live Share: See .vscode\docs\LiveShare-Setup.md"
Write-Host "  5. Start monitoring: .\LiveShare-Status.ps1"
Write-Host ""

# Create quick-access commands
$cmdFile = Join-Path $LocalOpsDir 'COMMANDS.md'
@"
# PrecisePointway Command Center - Quick Commands

## Fleet Management
``````powershell
# Deploy automation to fleet
.\scripts\FleetBootstrap.ps1 -Targets pc-1,pc-2,pc-3,pc-4

# Queue command to specific PC
.\scripts\Queue-Command.ps1 -Hosts pc-1 -Code "ipconfig /all"

# Review fleet VS Code settings
.\scripts\Review-VSCode-Fleet.ps1 -Targets pc-1,pc-2,pc-3,pc-4
``````

## Live Share
``````powershell
# Check Live Share status
.\scripts\LiveShare-Status.ps1

# Quick join Live Share session
.\scripts\LiveShare-QuickJoin.ps1
``````

## Monitoring
``````powershell
# Ship logs to NAS
.\scripts\Ship-Logs.ps1

# Full auto-run (pull, build, test, start Live Share)
.\scripts\Full-AutoRun.ps1
``````

## Recovery
``````powershell
# Recover corrupted VS Code on remote PC
.\scripts\Recover-VSCode-PC.ps1 -Target pc-1
``````

## Configuration
- Command Center Config: $configFile
- Fleet Inventory: $inventoryFile
- Network Discovery: $discoveryFile
"@ | Set-Content -Path $cmdFile -Encoding UTF8

Write-Host "Quick command reference created: $cmdFile" -ForegroundColor Green
Write-Host ""
