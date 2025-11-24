<#
Blade-IP-File-Audit-Pack.ps1 - Complete Multi-PC and Cloud Drive Audit
?? "Thy word is a lamp unto my feet, and a light unto my path." (Psalm 119:105 KJV)
?? "In a world you can be anything – be nice."

BLADE IP+FILE AUDIT PACK - ZERO FLUFF
- Enumerate IPs, mounted drives, all files across 4 PCs + clouds
- SHA-256 hash everything with integrity verification
- Flag chronological gaps and repo corruption
- Read-only operation with collaborative kindness
#>

param(
    [string]$ConfigFile = "config\blade_audit_config.yaml",
    [switch]$FullAudit,
    [switch]$QuickScan,
    [switch]$CloudOnly,
    [switch]$RepoCheck,
    [string]$OutputDir = "out"
)

$auditTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$hostname = $env:COMPUTERNAME
$auditDir = Join-Path $PSScriptRoot $OutputDir
$hostOutputDir = Join-Path $auditDir $hostname
$auditLog = Join-Path $hostOutputDir "blade_audit_$auditTimestamp.log"

# Ensure directories exist
New-Item -ItemType Directory -Force -Path $hostOutputDir | Out-Null
@("manifests", "hashes", "timelines", "repos", "clouds", "networks") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path (Join-Path $hostOutputDir $_) | Out-Null
}

function Write-AuditLog {
    param([string]$Message, [string]$Level = "AUDIT")
    $time = Get-Date -Format "HH:mm:ss"
    $entry = "[$time] [BLADE-AUDIT] [$Level] $Message"
    $colors = @{ 
        "AUDIT" = "Cyan"; "NETWORK" = "Green"; "FILES" = "Yellow"; 
        "HASH" = "Blue"; "REPO" = "Magenta"; "CLOUD" = "White";
        "GAP" = "Red"; "SUCCESS" = "Green"; "BIBLICAL" = "DarkGreen"
    }
    Write-Host $entry -ForegroundColor $colors[$Level]
    Add-Content -Path $auditLog -Value $entry -ErrorAction SilentlyContinue
}

function Get-BladeAuditConfig {
    Write-AuditLog "?? Loading Blade audit configuration..." "AUDIT"
    
    # Default configuration if file doesn't exist
    $defaultConfig = @{
        audit_roots = @(
            "C:\Users\$env:USERNAME\Documents",
            "C:\Users\$env:USERNAME\Desktop", 
            "C:\Users\$env:USERNAME\Downloads",
            "C:\source",
            "D:\source",
            "C:\PrecisePointway",
            "D:\PrecisePointway"
        )
        cloud_paths = @{
            google_drive = @(
                "C:\Users\$env:USERNAME\Google Drive",
                "G:\My Drive",
                "G:\"
            )
            onedrive = @(
                "C:\Users\$env:USERNAME\OneDrive",
                "C:\Users\$env:USERNAME\OneDrive - Personal"
            )
            icloud = @(
                "C:\Users\$env:USERNAME\iCloudDrive"
            )
            dropbox = @(
                "C:\Users\$env:USERNAME\Dropbox"
            )
        }
        nas_paths = @(
            "\\dxp4800plus-67ba\ops",
            "\\192.168.4.43\Truthios"
        )
        project_buckets = @{
            TruthIOS = @("TruthIOS", "truthios", "LightOS")
            TruthHub = @("TruthHub", "truth-hub")
            VIPFish = @("VIP", "fish", "vip-fish")
            Blade2Ark = @("Blade2", "ark", "blade-ark")
            LMStudio = @("LM_Studio", "lm-studio", "lmstudio")
            Ollama = @("ollama", "Ollama")
            VisualStudio = @("Visual Studio", "vs", "visualstudio")
            VSCode = @("vscode", "VS Code", ".vscode")
            PrecisePointway = @("PrecisePointway", "precisepointway")
            ProjectSunflower = @("Sunflower", "sunflower")
            CovenantPack = @("Covenant", "covenant", "Trial-Covenant")
        }
        exclusions = @(
            "*.tmp", "*.bak", "*.log", "thumbs.db", "desktop.ini", 
            "node_modules", ".git\objects", "bin", "obj", "Debug", "Release",
            "packages", ".vs", ".vscode\extensions"
        )
        timeline_gap_days = @{
            default_expected_activity = 7
            warning_threshold = 14
            critical_threshold = 30
        }
        hash_settings = @{
            large_file_threshold_mb = 100
            chunk_size_mb = 10
            use_full_hash_for_large_files = $false
        }
    }
    
    return $defaultConfig
}

function Get-NetworkConfiguration {
    Write-AuditLog "?? Scanning network configuration and mounted drives..." "NETWORK"
    
    $networkInfo = @{
        hostname = $env:COMPUTERNAME
        domain = $env:USERDOMAIN
        username = $env:USERNAME
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        ip_addresses = @()
        mounted_drives = @()
        network_shares = @()
        cloud_sync_status = @()
    }
    
    # Get IP addresses
    try {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($adapter in $adapters) {
            $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            if ($ipConfig) {
                $networkInfo.ip_addresses += @{
                    interface = $adapter.Name
                    ip_address = $ipConfig.IPAddress
                    subnet_mask = $ipConfig.PrefixLength
                    mac_address = $adapter.MacAddress
                }
            }
        }
    } catch {
        Write-AuditLog "Warning: Could not enumerate network adapters: $_" "NETWORK"
    }
    
    # Get mounted drives
    try {
        $drives = Get-WmiObject -Class Win32_LogicalDisk
        foreach ($drive in $drives) {
            $driveInfo = @{
                letter = $drive.DeviceID
                type = switch ($drive.DriveType) {
                    2 { "Removable" }
                    3 { "Fixed" }
                    4 { "Network" }
                    5 { "CD-ROM" }
                    6 { "RAM" }
                    default { "Unknown" }
                }
                file_system = $drive.FileSystem
                size_gb = if ($drive.Size) { [math]::Round($drive.Size / 1GB, 2) } else { 0 }
                free_gb = if ($drive.FreeSpace) { [math]::Round($drive.FreeSpace / 1GB, 2) } else { 0 }
                volume_name = $drive.VolumeName
            }
            $networkInfo.mounted_drives += $driveInfo
        }
    } catch {
        Write-AuditLog "Warning: Could not enumerate drives: $_" "NETWORK"
    }
    
    # Get network shares
    try {
        $shares = Get-SmbMapping -ErrorAction SilentlyContinue
        foreach ($share in $shares) {
            $networkInfo.network_shares += @{
                local_path = $share.LocalPath
                remote_path = $share.RemotePath
                status = $share.Status
            }
        }
    } catch {
        Write-AuditLog "Network shares enumeration not available" "NETWORK"
    }
    
    $networkFile = Join-Path $hostOutputDir "networks\network_config.json"
    $networkInfo | ConvertTo-Json -Depth 5 | Set-Content $networkFile -Encoding UTF8
    Write-AuditLog "?? Network configuration saved: $networkFile" "NETWORK"
    
    return $networkInfo
}

function Get-FileHashSafe {
    param(
        [string]$FilePath,
        [hashtable]$HashSettings
    )
    
    try {
        $fileInfo = Get-Item $FilePath -ErrorAction Stop
        $fileSizeMB = $fileInfo.Length / 1MB
        
        if ($fileSizeMB -gt $HashSettings.large_file_threshold_mb -and -not $HashSettings.use_full_hash_for_large_files) {
            # Hash first and last chunks for large files
            $chunkSize = $HashSettings.chunk_size_mb * 1MB
            $fileStream = [System.IO.File]::OpenRead($FilePath)
            
            # First chunk
            $firstChunk = New-Object byte[] $chunkSize
            $bytesRead1 = $fileStream.Read($firstChunk, 0, $chunkSize)
            
            # Last chunk
            $fileStream.Seek(-$chunkSize, [System.IO.SeekOrigin]::End)
            $lastChunk = New-Object byte[] $chunkSize
            $bytesRead2 = $fileStream.Read($lastChunk, 0, $chunkSize)
            
            $fileStream.Close()
            
            # Combine chunks and hash
            $combinedChunk = $firstChunk[0..($bytesRead1-1)] + $lastChunk[0..($bytesRead2-1)]
            $hashAlgorithm = [System.Security.Cryptography.SHA256]::Create()
            $hashBytes = $hashAlgorithm.ComputeHash($combinedChunk)
            $hash = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
            
            return @{
                hash = $hash.ToLower()
                method = "chunk"
                size = $fileInfo.Length
            }
        } else {
            # Full file hash for smaller files
            $hash = Get-FileHash $FilePath -Algorithm SHA256
            return @{
                hash = $hash.Hash.ToLower()
                method = "full"
                size = $fileInfo.Length
            }
        }
    } catch {
        return @{
            hash = "ERROR"
            method = "failed"
            size = 0
            error = $_.Exception.Message
        }
    }
}

function Test-PathExclusion {
    param(
        [string]$Path,
        [array]$Exclusions
    )
    
    foreach ($exclusion in $Exclusions) {
        if ($Path -like "*$exclusion*") {
            return $true
        }
    }
    return $false
}

function Invoke-FileSystemAudit {
    param(
        [array]$AuditRoots,
        [hashtable]$Config
    )
    
    Write-AuditLog "?? Starting comprehensive file system audit..." "FILES"
    
    $fileManifest = @{
        hostname = $env:COMPUTERNAME
        audit_timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        total_files = 0
        total_size_bytes = 0
        audit_roots = $AuditRoots
        files = @()
        errors = @()
        project_buckets = @{}
    }
    
    foreach ($root in $AuditRoots) {
        if (-not (Test-Path $root)) {
            Write-AuditLog "?? Path not found: $root" "FILES"
            continue
        }
        
        Write-AuditLog "?? Scanning: $root" "FILES"
        
        try {
            $files = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue | 
                     Where-Object { -not (Test-PathExclusion $_.FullName $Config.exclusions) }
            
            foreach ($file in $files) {
                try {
                    $hashResult = Get-FileHashSafe $file.FullName $Config.hash_settings
                    
                    $fileRecord = @{
                        path = $file.FullName
                        name = $file.Name
                        extension = $file.Extension
                        size = $file.Length
                        created = $file.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
                        modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                        accessed = $file.LastAccessTime.ToString("yyyy-MM-dd HH:mm:ss")
                        hash = $hashResult.hash
                        hash_method = $hashResult.method
                        bucket = $null
                    }
                    
                    # Assign to project bucket
                    foreach ($bucketName in $Config.project_buckets.Keys) {
                        foreach ($pattern in $Config.project_buckets[$bucketName]) {
                            if ($file.FullName -like "*$pattern*") {
                                $fileRecord.bucket = $bucketName
                                break
                            }
                        }
                        if ($fileRecord.bucket) { break }
                    }
                    
                    $fileManifest.files += $fileRecord
                    $fileManifest.total_files++
                    $fileManifest.total_size_bytes += $file.Length
                    
                    # Group by bucket
                    if ($fileRecord.bucket) {
                        if (-not $fileManifest.project_buckets.ContainsKey($fileRecord.bucket)) {
                            $fileManifest.project_buckets[$fileRecord.bucket] = @()
                        }
                        $fileManifest.project_buckets[$fileRecord.bucket] += $fileRecord
                    }
                    
                } catch {
                    $fileManifest.errors += @{
                        path = $file.FullName
                        error = $_.Exception.Message
                        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    }
                }
            }
        } catch {
            Write-AuditLog "? Error scanning $root : $_" "FILES"
        }
    }
    
    $manifestFile = Join-Path $hostOutputDir "manifests\file_manifest.json"
    $fileManifest | ConvertTo-Json -Depth 6 | Set-Content $manifestFile -Encoding UTF8
    Write-AuditLog "?? File manifest saved: $manifestFile ($('{0:N0}' -f $fileManifest.total_files) files)" "FILES"
    
    return $fileManifest
}

function Test-GitRepositories {
    param([hashtable]$FileManifest)
    
    Write-AuditLog "?? Checking Git repositories for corruption and status..." "REPO"
    
    $repoChecks = @{
        hostname = $env:COMPUTERNAME
        check_timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        repositories = @()
    }
    
    # Find .git directories
    $gitDirs = $FileManifest.files | Where-Object { $_.path -like "*\.git\*" -and $_.name -eq "HEAD" } | 
               ForEach-Object { Split-Path (Split-Path $_.path -Parent) -Parent } | 
               Sort-Object -Unique
    
    foreach ($repoPath in $gitDirs) {
        if (Test-Path (Join-Path $repoPath ".git")) {
            Write-AuditLog "?? Checking repository: $repoPath" "REPO"
            
            $repoInfo = @{
                path = $repoPath
                status = "unknown"
                branch = "unknown"
                last_commit = "unknown"
                dirty = $false
                remotes = @()
                fsck_status = "not_checked"
                errors = @()
            }
            
            try {
                Push-Location $repoPath
                
                # Get branch
                $branch = git rev-parse --abbrev-ref HEAD 2>$null
                if ($LASTEXITCODE -eq 0) { $repoInfo.branch = $branch }
                
                # Get last commit
                $lastCommit = git log -1 --format="%H %ci %s" 2>$null
                if ($LASTEXITCODE -eq 0) { $repoInfo.last_commit = $lastCommit }
                
                # Check if dirty
                $status = git status --porcelain 2>$null
                if ($LASTEXITCODE -eq 0) { 
                    $repoInfo.dirty = ($status.Count -gt 0)
                    $repoInfo.status = if ($repoInfo.dirty) { "dirty" } else { "clean" }
                }
                
                # Get remotes
                $remotes = git remote -v 2>$null
                if ($LASTEXITCODE -eq 0) { $repoInfo.remotes = $remotes }
                
                # Quick fsck
                $fsckOutput = git fsck --no-progress 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $repoInfo.fsck_status = "clean"
                } else {
                    $repoInfo.fsck_status = "errors"
                    $repoInfo.errors += "fsck: $fsckOutput"
                }
                
                Pop-Location
                
            } catch {
                $repoInfo.errors += $_.Exception.Message
                Pop-Location
            }
            
            $repoChecks.repositories += $repoInfo
        }
    }
    
    $repoFile = Join-Path $hostOutputDir "repos\git_checks.json"
    $repoChecks | ConvertTo-Json -Depth 5 | Set-Content $repoFile -Encoding UTF8
    Write-AuditLog "?? Git repository checks saved: $repoFile" "REPO"
    
    return $repoChecks
}

function Find-TimelineGaps {
    param([hashtable]$FileManifest, [hashtable]$Config)
    
    Write-AuditLog "?? Analyzing timeline gaps in project buckets..." "GAP"
    
    $timelineAnalysis = @{
        hostname = $env:COMPUTERNAME
        analysis_timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        bucket_timelines = @{}
        gaps_found = @()
    }
    
    foreach ($bucketName in $FileManifest.project_buckets.Keys) {
        $bucketFiles = $FileManifest.project_buckets[$bucketName]
        
        if ($bucketFiles.Count -eq 0) { continue }
        
        # Group files by date (modified time)
        $filesByDate = @{}
        foreach ($file in $bucketFiles) {
            $date = ([DateTime]$file.modified).Date.ToString("yyyy-MM-dd")
            if (-not $filesByDate.ContainsKey($date)) {
                $filesByDate[$date] = @()
            }
            $filesByDate[$date] += $file
        }
        
        # Sort dates and find gaps
        $sortedDates = $filesByDate.Keys | Sort-Object
        $gapThreshold = $Config.timeline_gap_days.default_expected_activity
        
        for ($i = 0; $i -lt ($sortedDates.Count - 1); $i++) {
            $currentDate = [DateTime]$sortedDates[$i]
            $nextDate = [DateTime]$sortedDates[$i + 1]
            $daysDiff = ($nextDate - $currentDate).Days
            
            if ($daysDiff -gt $gapThreshold) {
                $gap = @{
                    bucket = $bucketName
                    gap_start = $currentDate.ToString("yyyy-MM-dd")
                    gap_end = $nextDate.ToString("yyyy-MM-dd")
                    days_gap = $daysDiff
                    severity = if ($daysDiff -gt $Config.timeline_gap_days.critical_threshold) { "critical" } 
                              elseif ($daysDiff -gt $Config.timeline_gap_days.warning_threshold) { "warning" } 
                              else { "notice" }
                }
                $timelineAnalysis.gaps_found += $gap
            }
        }
        
        $timelineAnalysis.bucket_timelines[$bucketName] = @{
            total_files = $bucketFiles.Count
            date_range = @{
                earliest = $sortedDates[0]
                latest = $sortedDates[-1]
            }
            active_days = $sortedDates.Count
            files_by_date = $filesByDate
        }
    }
    
    $timelineFile = Join-Path $hostOutputDir "timelines\timeline_gaps.json"
    $timelineAnalysis | ConvertTo-Json -Depth 6 | Set-Content $timelineFile -Encoding UTF8
    Write-AuditLog "?? Timeline analysis saved: $timelineFile" "GAP"
    
    return $timelineAnalysis
}

function Invoke-CloudAudit {
    param([hashtable]$CloudPaths)
    
    Write-AuditLog "?? Auditing cloud synchronization folders..." "CLOUD"
    
    $cloudAudit = @{
        hostname = $env:COMPUTERNAME
        audit_timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        cloud_services = @{}
    }
    
    foreach ($serviceName in $CloudPaths.Keys) {
        $cloudAudit.cloud_services[$serviceName] = @{
            service = $serviceName
            paths_found = @()
            total_files = 0
            total_size_bytes = 0
            sync_status = "unknown"
        }
        
        foreach ($path in $CloudPaths[$serviceName]) {
            $expandedPath = $ExecutionContext.InvokeCommand.ExpandString($path)
            
            if (Test-Path $expandedPath) {
                Write-AuditLog "?? Found $serviceName at: $expandedPath" "CLOUD"
                
                try {
                    $files = Get-ChildItem -Path $expandedPath -Recurse -File -ErrorAction SilentlyContinue
                    $fileCount = $files.Count
                    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
                    
                    $cloudAudit.cloud_services[$serviceName].paths_found += @{
                        path = $expandedPath
                        files = $fileCount
                        size_bytes = $totalSize
                        last_scan = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    }
                    
                    $cloudAudit.cloud_services[$serviceName].total_files += $fileCount
                    $cloudAudit.cloud_services[$serviceName].total_size_bytes += $totalSize
                    
                } catch {
                    Write-AuditLog "? Error scanning $expandedPath : $_" "CLOUD"
                }
            }
        }
    }
    
    $cloudFile = Join-Path $hostOutputDir "clouds\cloud_audit.json"
    $cloudAudit | ConvertTo-Json -Depth 5 | Set-Content $cloudFile -Encoding UTF8
    Write-AuditLog "?? Cloud audit saved: $cloudFile" "CLOUD"
    
    return $cloudAudit
}

function New-AuditSummary {
    param(
        [hashtable]$NetworkInfo,
        [hashtable]$FileManifest,
        [hashtable]$RepoChecks,
        [hashtable]$TimelineAnalysis,
        [hashtable]$CloudAudit
    )
    
    Write-AuditLog "?? Generating comprehensive audit summary..." "SUCCESS"
    
    $summary = @{
        audit_info = @{
            hostname = $env:COMPUTERNAME
            audit_timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            audit_version = "BLADE-v1.0"
            total_duration_seconds = ((Get-Date) - $script:auditStartTime).TotalSeconds
        }
        network_summary = @{
            ip_addresses = $NetworkInfo.ip_addresses.Count
            mounted_drives = $NetworkInfo.mounted_drives.Count
            network_shares = $NetworkInfo.network_shares.Count
        }
        file_summary = @{
            total_files = $FileManifest.total_files
            total_size_gb = [math]::Round($FileManifest.total_size_bytes / 1GB, 2)
            project_buckets = $FileManifest.project_buckets.Keys.Count
            errors = $FileManifest.errors.Count
        }
        repo_summary = @{
            repositories_found = $RepoChecks.repositories.Count
            clean_repos = ($RepoChecks.repositories | Where-Object { $_.status -eq "clean" }).Count
            dirty_repos = ($RepoChecks.repositories | Where-Object { $_.dirty }).Count
            fsck_errors = ($RepoChecks.repositories | Where-Object { $_.fsck_status -eq "errors" }).Count
        }
        timeline_summary = @{
            buckets_analyzed = $TimelineAnalysis.bucket_timelines.Keys.Count
            gaps_found = $TimelineAnalysis.gaps_found.Count
            critical_gaps = ($TimelineAnalysis.gaps_found | Where-Object { $_.severity -eq "critical" }).Count
        }
        cloud_summary = @{
            services_found = ($CloudAudit.cloud_services.Values | Where-Object { $_.paths_found.Count -gt 0 }).Count
            total_cloud_files = ($CloudAudit.cloud_services.Values | Measure-Object -Property total_files -Sum).Sum
            total_cloud_size_gb = [math]::Round(($CloudAudit.cloud_services.Values | Measure-Object -Property total_size_bytes -Sum).Sum / 1GB, 2)
        }
        biblical_foundation = @{
            motto = "In a world you can be anything – be nice."
            scripture = "Thy word is a lamp unto my feet, and a light unto my path. (Psalm 119:105 KJV)"
            stewardship = "Moreover it is required in stewards, that a man be found faithful. (1 Corinthians 4:2 KJV)"
        }
    }
    
    $summaryFile = Join-Path $hostOutputDir "audit_summary.json"
    $summary | ConvertTo-Json -Depth 5 | Set-Content $summaryFile -Encoding UTF8
    Write-AuditLog "?? Audit summary saved: $summaryFile" "SUCCESS"
    
    return $summary
}

# Main Blade IP+File Audit Execution
$script:auditStartTime = Get-Date

Write-AuditLog ""
Write-AuditLog "?? BLADE IP+FILE AUDIT PACK EXECUTION" "AUDIT"
Write-AuditLog "?? 'Moreover it is required in stewards, that a man be found faithful.' (1 Corinthians 4:2 KJV)" "BIBLICAL"
Write-AuditLog "?? Comprehensive multi-PC and cloud drive audit with collaborative kindness" "AUDIT"
Write-AuditLog ""

# Load configuration
$config = Get-BladeAuditConfig

# Execute audit phases
Write-AuditLog "Phase 1: Network Configuration Scan" "AUDIT"
$networkInfo = Get-NetworkConfiguration

Write-AuditLog "Phase 2: File System Audit" "AUDIT"
$allPaths = $config.audit_roots + $config.nas_paths
$fileManifest = Invoke-FileSystemAudit -AuditRoots $allPaths -Config $config

if ($RepoCheck -or $FullAudit) {
    Write-AuditLog "Phase 3: Git Repository Checks" "AUDIT"
    $repoChecks = Test-GitRepositories -FileManifest $fileManifest
} else {
    $repoChecks = @{ repositories = @() }
}

Write-AuditLog "Phase 4: Timeline Gap Analysis" "AUDIT"
$timelineAnalysis = Find-TimelineGaps -FileManifest $fileManifest -Config $config

if ($CloudOnly -or $FullAudit -or (-not $QuickScan)) {
    Write-AuditLog "Phase 5: Cloud Synchronization Audit" "AUDIT"
    $cloudAudit = Invoke-CloudAudit -CloudPaths $config.cloud_paths
} else {
    $cloudAudit = @{ cloud_services = @{} }
}

Write-AuditLog "Phase 6: Summary Generation" "AUDIT"
$summary = New-AuditSummary -NetworkInfo $networkInfo -FileManifest $fileManifest -RepoChecks $repoChecks -TimelineAnalysis $timelineAnalysis -CloudAudit $cloudAudit

# Display results
Write-Host ""
Write-Host "?? BLADE IP+FILE AUDIT COMPLETE" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Gray
Write-Host ""
Write-Host "?? AUDIT RESULTS FOR: $hostname" -ForegroundColor Cyan
Write-Host ""
Write-Host "?? NETWORK CONFIGURATION:" -ForegroundColor Yellow
Write-Host "  IP Addresses: $($summary.network_summary.ip_addresses)" -ForegroundColor White
Write-Host "  Mounted Drives: $($summary.network_summary.mounted_drives)" -ForegroundColor White
Write-Host "  Network Shares: $($summary.network_summary.network_shares)" -ForegroundColor White
Write-Host ""
Write-Host "?? FILE SYSTEM AUDIT:" -ForegroundColor Yellow
Write-Host "  Total Files: $('{0:N0}' -f $summary.file_summary.total_files)" -ForegroundColor White
Write-Host "  Total Size: $($summary.file_summary.total_size_gb) GB" -ForegroundColor White
Write-Host "  Project Buckets: $($summary.file_summary.project_buckets)" -ForegroundColor White
Write-Host "  Errors: $($summary.file_summary.errors)" -ForegroundColor $(if ($summary.file_summary.errors -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "?? REPOSITORY STATUS:" -ForegroundColor Yellow
Write-Host "  Repositories Found: $($summary.repo_summary.repositories_found)" -ForegroundColor White
Write-Host "  Clean Repos: $($summary.repo_summary.clean_repos)" -ForegroundColor Green
Write-Host "  Dirty Repos: $($summary.repo_summary.dirty_repos)" -ForegroundColor $(if ($summary.repo_summary.dirty_repos -gt 0) { "Yellow" } else { "Green" })
Write-Host "  FSCK Errors: $($summary.repo_summary.fsck_errors)" -ForegroundColor $(if ($summary.repo_summary.fsck_errors -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "?? TIMELINE ANALYSIS:" -ForegroundColor Yellow
Write-Host "  Buckets Analyzed: $($summary.timeline_summary.buckets_analyzed)" -ForegroundColor White
Write-Host "  Gaps Found: $($summary.timeline_summary.gaps_found)" -ForegroundColor $(if ($summary.timeline_summary.gaps_found -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Critical Gaps: $($summary.timeline_summary.critical_gaps)" -ForegroundColor $(if ($summary.timeline_summary.critical_gaps -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "?? CLOUD SYNCHRONIZATION:" -ForegroundColor Yellow
Write-Host "  Services Found: $($summary.cloud_summary.services_found)" -ForegroundColor White
Write-Host "  Cloud Files: $('{0:N0}' -f $summary.cloud_summary.total_cloud_files)" -ForegroundColor White
Write-Host "  Cloud Size: $($summary.cloud_summary.total_cloud_size_gb) GB" -ForegroundColor White
Write-Host ""
Write-Host "?? OUTPUT DIRECTORY: $hostOutputDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "?? NEXT STEPS:" -ForegroundColor Blue
Write-Host "  1. Run this script on all PCs (pc-1, pc-2, pc-3, laptop)" -ForegroundColor White
Write-Host "  2. Collect all 'out' directories to one machine" -ForegroundColor White
Write-Host "  3. Run merge script to create unified manifest" -ForegroundColor White
Write-Host "  4. Review timeline gaps and repo issues" -ForegroundColor White
Write-Host ""
Write-Host "?? BIBLICAL FOUNDATION:" -ForegroundColor Blue
Write-Host "  'Moreover it is required in stewards, that a man be found faithful.'" -ForegroundColor Cyan
Write-Host "  (1 Corinthians 4:2 KJV)" -ForegroundColor Cyan
Write-Host ""
Write-Host "?? COLLABORATIVE MOTTO:" -ForegroundColor Magenta
Write-Host "  'In a world you can be anything – be nice.'" -ForegroundColor Magenta

Write-AuditLog ""
Write-AuditLog "?? Blade IP+File Audit completed successfully!" "SUCCESS"
Write-AuditLog "?? Results saved to: $hostOutputDir" "AUDIT"
Write-AuditLog "?? Total duration: $([math]::Round($summary.audit_info.total_duration_seconds, 2)) seconds" "AUDIT"
Write-AuditLog "?? Faithful stewardship audit completed under God's authority" "BIBLICAL"