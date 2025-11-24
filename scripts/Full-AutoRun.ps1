[CmdletBinding()]
param(
    [string]$Solution = (Join-Path (Split-Path -Parent $PSScriptRoot) 'PrecisePointway.sln'),
    [switch]$Release,
    [switch]$SkipLiveShare,
    [switch]$SkipAnalytics,
    [switch]$SkipNetworkTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    Write-Host "=== [START] $Name ===" -ForegroundColor Cyan
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $Action
        Write-Host "=== [OK] $Name ($($sw.Elapsed.ToString())) ===" -ForegroundColor Green
    }
    catch {
        Write-Host "=== [FAIL] $Name ($($sw.Elapsed.ToString())) ===" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        throw
    }
}

# 1. Git Pull
Invoke-Step 'Git Pull' { git pull | Write-Host }

# 2. Build
$configuration = if ($Release) { 'Release' } else { 'Debug' }
Invoke-Step "Build ($configuration)" {
    & msbuild $Solution "/p:Configuration=$configuration" "/p:Platform=x64" | Write-Host
}

# 3. Start Live Share Host (enhanced) if not skipped
if (-not $SkipLiveShare) {
    $lsScript = Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts/Start-LiveShare-Host.ps1'
    if (Test-Path $lsScript) {
        Invoke-Step 'Live Share Host Session' {
            & powershell -NoProfile -ExecutionPolicy Bypass -File $lsScript -WorkspacePath (Split-Path -Parent $PSScriptRoot) -AutoNotify -AutoDiscover -DetailedMetrics | Write-Host
        }
    } else { Write-Host 'Live Share script not found, skipping.' -ForegroundColor Yellow }
}

# 4. Network Optimization Test
if (-not $SkipNetworkTest) {
    $netScript = Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts/Test-LiveShare-Optimization.ps1'
    if (Test-Path $netScript) {
        Invoke-Step 'Network Optimization Test' {
            & powershell -NoProfile -ExecutionPolicy Bypass -File $netScript -AutoDiscover -PingCount 4 -ShowDetailedMetrics | Write-Host
        }
    } else { Write-Host 'Network test script not found, skipping.' -ForegroundColor Yellow }
}

# 5. Analytics Live Monitoring
if (-not $SkipAnalytics) {
    $analyticsScript = Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts/Analytics-LiveMonitoring.ps1'
    if (Test-Path $analyticsScript) {
        Invoke-Step 'Analytics Live Monitoring' {
            & powershell -NoProfile -ExecutionPolicy Bypass -File $analyticsScript | Write-Host
        }
    } else { Write-Host 'Analytics monitoring script not found, skipping.' -ForegroundColor Yellow }
}

# 6. Summary
Write-Host "=== FULL AUTO RUN COMPLETED ($configuration) ===" -ForegroundColor Magenta
