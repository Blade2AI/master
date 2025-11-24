# COMPREHENSIVE MULTI-PC AND CLOUD AUDIT - COMPLETE CLOSURE
# ?? "Thy word is a lamp unto my feet, and a light unto my path." (Psalm 119:105 KJV)
# ?? "In a world you can be anything – be nice."

param(
    [switch]$FullAudit,
    [switch]$CloudScan,
    [switch]$IPDiscovery,
    [switch]$RunAllToClose
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$auditRoot = Join-Path $env:USERPROFILE "ComprehensiveAudit_$timestamp"
New-Item -ItemType Directory -Force -Path $auditRoot | Out-Null

function Write-AuditLog {
    param([string]$Message, [string]$Level = "INFO")
    $time = Get-Date -Format "HH:mm:ss"
    $entry = "[$time] [AUDIT] [$Level] $Message"
    $color = switch ($Level) { "ERROR" {"Red"} "WARN" {"Yellow"} "SUCCESS" {"Green"} "BIBLICAL" {"Blue"} default {"White"} }
    Write-Host $entry -ForegroundColor $color
    Add-Content -Path (Join-Path $auditRoot "comprehensive_audit.log") -Value $entry
}

Write-AuditLog "?? 'Moreover it is required in stewards, that a man be found faithful.' (1 Corinthians 4:2 KJV)" "BIBLICAL"
Write-AuditLog "?? Starting comprehensive multi-PC and cloud audit for PrecisePointway" "SUCCESS"

# 1. NETWORK AND IP DISCOVERY
Write-AuditLog "Phase 1: Network and IP Discovery" "INFO"
$networkAudit = @{
    hostname = $env:COMPUTERNAME
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    ip_addresses = @()
    drives = @()
    cloud_paths = @()
    nas_shares = @()
}

# Get network configuration
try {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    foreach ($adapter in $adapters) {
        $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if ($ipConfig) {
            $networkAudit.ip_addresses += @{
                interface = $adapter.Name
                ip = $ipConfig.IPAddress
                mac = $adapter.MacAddress
            }
        }
    }
    Write-AuditLog "? Network configuration captured: $($networkAudit.ip_addresses.Count) interfaces" "SUCCESS"
} catch {
    Write-AuditLog "?? Network enumeration warning: $_" "WARN"
}

# Get all drives
$drives = Get-WmiObject -Class Win32_LogicalDisk
foreach ($drive in $drives) {
    $networkAudit.drives += @{
        letter = $drive.DeviceID
        type = switch ($drive.DriveType) { 2 {"Removable"} 3 {"Fixed"} 4 {"Network"} 5 {"CD-ROM"} default {"Unknown"} }
        size_gb = if ($drive.Size) { [math]::Round($drive.Size / 1GB, 2) } else { 0 }
        free_gb = if ($drive.FreeSpace) { [math]::Round($drive.FreeSpace / 1GB, 2) } else { 0 }
        label = $drive.VolumeName
    }
}
Write-AuditLog "? Drive enumeration: $($networkAudit.drives.Count) drives found" "SUCCESS"

# 2. CLOUD STORAGE DISCOVERY
Write-AuditLog "Phase 2: Cloud Storage Discovery" "INFO"
$cloudPaths = @{
    "Google Drive" = @(
        "C:\Users\$env:USERNAME\Google Drive",
        "G:\My Drive",
        "G:\"
    )
    "OneDrive" = @(
        "C:\Users\$env:USERNAME\OneDrive",
        "$env:USERPROFILE\OneDrive"
    )
    "iCloud" = @(
        "C:\Users\$env:USERNAME\iCloudDrive",
        "$env:USERPROFILE\iCloudDrive"
    )
    "Dropbox" = @(
        "C:\Users\$env:USERNAME\Dropbox",
        "$env:USERPROFILE\Dropbox"
    )
}

$foundClouds = @{}
foreach ($service in $cloudPaths.Keys) {
    $foundClouds[$service] = @()
    foreach ($path in $cloudPaths[$service]) {
        $expandedPath = $ExecutionContext.InvokeCommand.ExpandString($path)
        if (Test-Path $expandedPath) {
            $files = Get-ChildItem -Path $expandedPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object
            $foundClouds[$service] += @{
                path = $expandedPath
                files = $files.Count
                last_check = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            Write-AuditLog "?? Found $service at: $expandedPath ($($files.Count) files)" "SUCCESS"
        }
    }
}

# 3. NAS AND NETWORK SHARES
Write-AuditLog "Phase 3: NAS and Network Share Discovery" "INFO"
$nasTargets = @(
    "\\dxp4800plus-67ba\ops",
    "\\192.168.4.43\Truthios",
    "\\nas\shared"
)

$accessibleNAS = @()
foreach ($nas in $nasTargets) {
    try {
        if (Test-Path $nas -ErrorAction SilentlyContinue) {
            $files = Get-ChildItem -Path $nas -ErrorAction SilentlyContinue | Measure-Object
            $accessibleNAS += @{
                path = $nas
                accessible = $true
                files = $files.Count
                error = $null
            }
            Write-AuditLog "?? NAS accessible: $nas ($($files.Count) items)" "SUCCESS"
        } else {
            $accessibleNAS += @{
                path = $nas
                accessible = $false
                files = 0
                error = "Path not accessible"
            }
            Write-AuditLog "? NAS not accessible: $nas" "ERROR"
        }
    } catch {
        $accessibleNAS += @{
            path = $nas
            accessible = $false
            files = 0
            error = $_.Exception.Message
        }
        Write-AuditLog "? NAS error: $nas - $_" "ERROR"
    }
}

# 4. PROJECT BUCKET ANALYSIS
Write-AuditLog "Phase 4: Project Bucket Analysis" "INFO"
$projectBuckets = @{
    "PrecisePointway" = @("PrecisePointway", "precisepointway")
    "TruthIOS" = @("TruthIOS", "truthios", "LightOS")
    "Blade2_Ark" = @("Blade2", "ark", "blade")
    "VIP_Fish" = @("VIP", "fish", "vip")
    "AI_Models" = @("LM_Studio", "ollama", "models")
    "Development" = @("Visual Studio", "vscode", "source", "repos")
    "Chat_Exports" = @("ChatGPT", "conversations", "exports")
}

$bucketFindings = @{}
$searchRoots = @(
    "C:\Users\$env:USERNAME\Documents",
    "C:\Users\$env:USERNAME\Desktop",
    "C:\source",
    "D:\source",
    "C:\",
    "D:\"
)

foreach ($bucket in $projectBuckets.Keys) {
    $bucketFindings[$bucket] = @()
    $patterns = $projectBuckets[$bucket]
    
    foreach ($root in $searchRoots) {
        $expandedRoot = $ExecutionContext.InvokeCommand.ExpandString($root)
        if (Test-Path $expandedRoot) {
            foreach ($pattern in $patterns) {
                try {
                    $found = Get-ChildItem -Path $expandedRoot -Recurse -Directory -Name "*$pattern*" -ErrorAction SilentlyContinue | Select-Object -First 10
                    foreach ($item in $found) {
                        $fullPath = Join-Path $expandedRoot $item
                        $bucketFindings[$bucket] += @{
                            path = $fullPath
                            pattern = $pattern
                            found_in = $expandedRoot
                        }
                    }
                } catch {
                    # Silent continue for access errors
                }
            }
        }
    }
    Write-AuditLog "?? Project bucket '$bucket': $($bucketFindings[$bucket].Count) locations found" "INFO"
}

# 5. ACCESS GAPS AND ISSUES ANALYSIS
Write-AuditLog "Phase 5: Access Gaps and Issues Analysis" "INFO"
$accessGaps = @{
    missing_cloud_services = @()
    inaccessible_nas = @()
    missing_project_buckets = @()
    permission_issues = @()
}

# Check for missing cloud services
foreach ($service in $cloudPaths.Keys) {
    if ($foundClouds[$service].Count -eq 0) {
        $accessGaps.missing_cloud_services += $service
        Write-AuditLog "? Missing cloud service: $service" "ERROR"
    }
}

# Check for inaccessible NAS
foreach ($nas in $accessibleNAS) {
    if (-not $nas.accessible) {
        $accessGaps.inaccessible_nas += $nas.path
        Write-AuditLog "? Inaccessible NAS: $($nas.path) - $($nas.error)" "ERROR"
    }
}

# Check for missing project buckets
foreach ($bucket in $projectBuckets.Keys) {
    if ($bucketFindings[$bucket].Count -eq 0) {
        $accessGaps.missing_project_buckets += $bucket
        Write-AuditLog "?? Missing project bucket: $bucket" "WARN"
    }
}

# 6. COMPREHENSIVE SUMMARY GENERATION
Write-AuditLog "Phase 6: Comprehensive Summary Generation" "INFO"
$comprehensiveAudit = @{
    audit_info = @{
        hostname = $env:COMPUTERNAME
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        duration_seconds = ((Get-Date) - $timestamp).TotalSeconds
    }
    network_config = $networkAudit
    cloud_storage = $foundClouds
    nas_access = $accessibleNAS
    project_buckets = $bucketFindings
    access_gaps = $accessGaps
    summary = @{
        total_drives = $networkAudit.drives.Count
        accessible_clouds = ($foundClouds.Values | Where-Object { $_.Count -gt 0 }).Count
        accessible_nas = ($accessibleNAS | Where-Object { $_.accessible }).Count
        project_locations = ($bucketFindings.Values | Measure-Object -Property Count -Sum).Sum
        critical_gaps = $accessGaps.missing_cloud_services.Count + $accessGaps.inaccessible_nas.Count
    }
    biblical_foundation = @{
        scripture = "Thy word is a lamp unto my feet, and a light unto my path. (Psalm 119:105 KJV)"
        stewardship = "Moreover it is required in stewards, that a man be found faithful. (1 Corinthians 4:2 KJV)"
        motto = "In a world you can be anything – be nice."
    }
}

# Save comprehensive audit
$auditFile = Join-Path $auditRoot "comprehensive_audit_results.json"
$comprehensiveAudit | ConvertTo-Json -Depth 6 | Set-Content $auditFile -Encoding UTF8

# 7. DISPLAY RESULTS
Write-Host ""
Write-Host "?? COMPREHENSIVE AUDIT COMPLETE" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Gray
Write-Host ""
Write-Host "?? SUMMARY FOR: $($comprehensiveAudit.audit_info.hostname)" -ForegroundColor Cyan
Write-Host ""
Write-Host "?? NETWORK CONFIGURATION:" -ForegroundColor Yellow
Write-Host "  IP Interfaces: $($networkAudit.ip_addresses.Count)" -ForegroundColor White
Write-Host "  Total Drives: $($networkAudit.drives.Count)" -ForegroundColor White
Write-Host ""
Write-Host "?? CLOUD STORAGE ACCESS:" -ForegroundColor Yellow
foreach ($service in $foundClouds.Keys) {
    $count = $foundClouds[$service].Count
    $color = if ($count -gt 0) { "Green" } else { "Red" }
    Write-Host "  $service`: $count locations" -ForegroundColor $color
}
Write-Host ""
Write-Host "?? NAS ACCESS STATUS:" -ForegroundColor Yellow
foreach ($nas in $accessibleNAS) {
    $color = if ($nas.accessible) { "Green" } else { "Red" }
    $status = if ($nas.accessible) { "? ACCESSIBLE" } else { "? BLOCKED" }
    Write-Host "  $($nas.path): $status" -ForegroundColor $color
}
Write-Host ""
Write-Host "?? PROJECT BUCKET FINDINGS:" -ForegroundColor Yellow
foreach ($bucket in $bucketFindings.Keys) {
    $count = $bucketFindings[$bucket].Count
    $color = if ($count -gt 0) { "Green" } elseif ($count -eq 0) { "Red" } else { "Yellow" }
    Write-Host "  $bucket`: $count locations" -ForegroundColor $color
}
Write-Host ""
Write-Host "? ACCESS GAPS IDENTIFIED:" -ForegroundColor Red
Write-Host "  Missing Cloud Services: $($accessGaps.missing_cloud_services.Count)" -ForegroundColor $(if ($accessGaps.missing_cloud_services.Count -gt 0) { "Red" } else { "Green" })
if ($accessGaps.missing_cloud_services.Count -gt 0) {
    foreach ($missing in $accessGaps.missing_cloud_services) {
        Write-Host "    - $missing" -ForegroundColor Red
    }
}
Write-Host "  Inaccessible NAS: $($accessGaps.inaccessible_nas.Count)" -ForegroundColor $(if ($accessGaps.inaccessible_nas.Count -gt 0) { "Red" } else { "Green" })
if ($accessGaps.inaccessible_nas.Count -gt 0) {
    foreach ($missing in $accessGaps.inaccessible_nas) {
        Write-Host "    - $missing" -ForegroundColor Red
    }
}
Write-Host "  Missing Project Buckets: $($accessGaps.missing_project_buckets.Count)" -ForegroundColor $(if ($accessGaps.missing_project_buckets.Count -gt 0) { "Yellow" } else { "Green" })
if ($accessGaps.missing_project_buckets.Count -gt 0) {
    foreach ($missing in $accessGaps.missing_project_buckets) {
        Write-Host "    - $missing" -ForegroundColor Yellow
    }
}
Write-Host ""
Write-Host "?? AUDIT RESULTS SAVED TO: $auditRoot" -ForegroundColor Cyan
Write-Host ""
Write-Host "?? BIBLICAL FOUNDATION:" -ForegroundColor Blue
Write-Host "  'Moreover it is required in stewards, that a man be found faithful.'" -ForegroundColor Cyan
Write-Host "  (1 Corinthians 4:2 KJV)" -ForegroundColor Cyan
Write-Host ""
Write-Host "?? COLLABORATIVE MOTTO:" -ForegroundColor Magenta
Write-Host "  'In a world you can be anything – be nice.'" -ForegroundColor Magenta

Write-AuditLog "?? Comprehensive audit completed successfully!" "SUCCESS"
Write-AuditLog "?? Results saved to: $auditRoot" "INFO"

return $comprehensiveAudit