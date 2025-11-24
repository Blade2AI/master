<#
.SYNOPSIS
Single-entry Sovereign Fleet script.

Modes:
  -SnapshotOnly   ? Run emergency snapshot on THIS machine (PC1/PC2/PC3/etc).
                    Creates C:\FLEET_AUDIT_<NODE>_<timestamp>\...

  -FullFleet      ? From PC4 (Command Node):
                    • Pull latest FLEET_AUDIT_<NODE>_* from each node via admin share
                    • Stage into AUDIT_INPUT
                    • Run Consolidate-AuditFleet.ps1
                    • Run Generate-SafeCutList.ps1

Nothing here deletes anything.
#>

param(
    [switch]$SnapshotOnly,
    [switch]$FullFleet,

    # Logical name for this node in the fleet (defaults to COMPUTERNAME)
    [string]$NodeName = $env:COMPUTERNAME,

    # Where snapshots are created on each node
    [string]$SnapshotRootParent = "C:\",

    # Command-node only: where we stage per-node audits
    [string]$AuditInputRoot = "C:\Users\andyj\AUDIT_INPUT",

    # Command-node only: PrecisePointway repo root
    [string]$RepoRoot = "C:\Users\andyj\source\repos\PrecisePointway\master",

    # Command-node only: mapping NodeName ? remote root (edit as your real hostnames)
    [hashtable]$Nodes = @{
        "PC3" = "\\PC3\C$"
        # Add more as you standardise snapshots:
        # "PC1" = "\\PC1\C$"
        # "PC2" = "\\PC2\C$"
        # "PC4" = "C:\"    
    }
)

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

# -------------------------------------------------------------------------
# 1. Emergency snapshot on THIS node
# -------------------------------------------------------------------------
function Invoke-EmergencySnapshot {
    param(
        [string]$NodeName,
        [string]$SnapshotRootParent
    )

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $root  = Join-Path $SnapshotRootParent ("FLEET_AUDIT_{0}_{1}" -f $NodeName, $stamp)

    Write-Host "=== EMERGENCY SNAPSHOT START ===" -ForegroundColor Cyan
    Write-Host "Node     : $NodeName"
    Write-Host "Root dir : $root"
    Ensure-Dir $root

    # ---- System info -----------------------------------------------------
    $sysDir = Join-Path $root "system"
    Ensure-Dir $sysDir

    Write-Host "Capturing system info..." -ForegroundColor Cyan
    systeminfo | Out-File -FilePath (Join-Path $sysDir "systeminfo.txt") -Encoding UTF8
    Get-ComputerInfo | Out-File -FilePath (Join-Path $sysDir "computerinfo.txt") -Encoding UTF8

    Write-Host "Capturing running processes..." -ForegroundColor Cyan
    Get-Process | Select-Object Name,Id,CPU,WS,StartTime |
        Export-Csv -LiteralPath (Join-Path $sysDir "processes.csv") -NoTypeInformation -Encoding UTF8

    Write-Host "Capturing services..." -ForegroundColor Cyan
    Get-Service | Select-Object Name,DisplayName,Status,StartType |
        Export-Csv -LiteralPath (Join-Path $sysDir "services.csv") -NoTypeInformation -Encoding UTF8

    Write-Host "Capturing installed software..." -ForegroundColor Cyan
    $installed = @()
    $uninstallRoots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )

    foreach ($rootKey in $uninstallRoots) {
        if (Test-Path $rootKey) {
            Get-ChildItem $rootKey | ForEach-Object {
                $p = Get-ItemProperty -Path $_.PsPath -ErrorAction SilentlyContinue
                if ($p.DisplayName) {
                    $installed += [PSCustomObject]@{
                        DisplayName    = $p.DisplayName
                        DisplayVersion = $p.DisplayVersion
                        Publisher      = $p.Publisher
                        InstallDate    = $p.InstallDate
                        UninstallKey   = $_.PsPath
                    }
                }
            }
        }
    }

    $installed | Sort-Object DisplayName |
        Export-Csv -LiteralPath (Join-Path $sysDir "installed_software.csv") -NoTypeInformation -Encoding UTF8

    # ---- Deep file inventory ---------------------------------------------
    $filesDir = Join-Path $root "files"
    Ensure-Dir $filesDir

    Write-Host "Scanning code/text files (this may take a while)..." -ForegroundColor Cyan

    $scanRoots = @(
        "$env:USERPROFILE",
        "C:\source",
        "C:\src",
        "C:\Projects",
        "D:\"
    ) | Where-Object { Test-Path $_ }

    $extensions = @(
        '*.ps1','*.psm1','*.psd1',
        '*.bat','*.cmd',
        '*.py','*.js','*.ts','*.tsx','*.jsx',
        '*.cs','*.sln','*.fs','*.vb',
        '*.sql','*.yml','*.yaml','*.json','*.xml','*.ini','*.cfg','*.env',
        '*.md','*.txt','*.rst'
    )

    $deepRows = @()
    foreach ($rootPath in $scanRoots) {
        Write-Host "  ? scanning $rootPath" -ForegroundColor DarkGray
        foreach ($ext in $extensions) {
            Get-ChildItem -Path $rootPath -Recurse -Filter $ext -ErrorAction SilentlyContinue |
                Where-Object { -not $_.PSIsContainer } |
                ForEach-Object {
                    $deepRows += [PSCustomObject]@{
                        Node         = $NodeName
                        Path         = $_.FullName
                        SizeKB       = [math]::Round($_.Length / 1kb, 2)
                        LastModified = $_.LastWriteTime
                        Extension    = $_.Extension
                    }
                }
        }
    }

    $deepPath = Join-Path $filesDir ("{0}_DEEP_FORGE.csv" -f $NodeName)
    $deepRows |
        Sort-Object Path |
        Export-Csv -LiteralPath $deepPath -NoTypeInformation -Encoding UTF8

    # ---- Model inventory -------------------------------------------------
    $modelsDir = Join-Path $root "models"
    Ensure-Dir $modelsDir

    Write-Host "Scanning for local AI model files..." -ForegroundColor Cyan

    $modelRoots = @(
        "$env:USERPROFILE\.lmstudio\models",
        "C:\Models",
        "C:\AI\Models",
        "D:\LLM",
        "C:\ProgramData\ollama\models"
    ) | Where-Object { Test-Path $_ }

    $modelRows = @()
    foreach ($mr in $modelRoots) {
        Write-Host "  ? scanning model root $mr" -ForegroundColor DarkGray
        Get-ChildItem -Path $mr -Recurse -ErrorAction SilentlyContinue |
            Where-Object { -not $_.PSIsContainer } |
            ForEach-Object {
                $modelRows += [PSCustomObject]@{
                    Node         = $NodeName
                    Path         = $_.FullName
                    SizeMB       = [math]::Round($_.Length / 1mb, 2)
                    LastModified = $_.LastWriteTime
                }
            }
    }

    $modelPath = Join-Path $modelsDir ("{0}_AI_MODELS.csv" -f $NodeName)
    $modelRows |
        Sort-Object Path |
        Export-Csv -LiteralPath $modelPath -NoTypeInformation -Encoding UTF8

    Write-Host ""; Write-Host "=== EMERGENCY SNAPSHOT COMPLETE ===" -ForegroundColor Green
    Write-Host "Node     : $NodeName"
    Write-Host "Root dir : $root"
    Write-Host ("Files    : {0} (rows: {1})" -f $deepPath,   ($deepRows.Count))
    Write-Host ("Models   : {0} (rows: {1})" -f $modelPath, ($modelRows.Count))
}

# -------------------------------------------------------------------------
# 2. Full fleet consolidation on Command Node (PC4)
# -------------------------------------------------------------------------
function Invoke-FullFleetAudit {
    param(
        [string]$AuditInputRoot,
        [string]$RepoRoot,
        [hashtable]$Nodes
    )

    Write-Host "=== SOVEREIGN FLEET AUDIT – FULL RUN ===" -ForegroundColor Cyan
    Write-Host "Repo root        : $RepoRoot"
    Write-Host "Audit input root : $AuditInputRoot"; Write-Host ""

    Ensure-Dir $AuditInputRoot

    $localAuditRoots = @()

    foreach ($nodeName in $Nodes.Keys) {
        $shareRoot = $Nodes[$nodeName]
        Write-Host "? Processing node: $nodeName (share: $shareRoot)" -ForegroundColor White
        if (-not (Test-Path $shareRoot)) { Write-Warning "  Cannot reach $shareRoot – skipping $nodeName"; continue }
        $pattern = "FLEET_AUDIT_${nodeName}_*"
        $candidates = Get-ChildItem -Path $shareRoot -Directory -Filter $pattern -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        if (-not $candidates) { Write-Warning "  No matching $pattern found on $shareRoot – skipping."; continue }
        $latest = $candidates[0]
        Write-Host "  Latest snapshot: $($latest.FullName)" -ForegroundColor DarkGray
        $suffix = $latest.Name.Substring(("FLEET_AUDIT_{0}_" -f $nodeName).Length)
        $dest   = Join-Path $AuditInputRoot ("_AUDIT_RESULTS_{0}_{1}" -f $nodeName, $suffix)
        Write-Host "  Staging to: $dest" -ForegroundColor DarkGray
        Ensure-Dir $dest
        Copy-Item -Path $latest.FullName\* -Destination $dest -Recurse -Force
        $localAuditRoots += $dest
    }

    if (-not $localAuditRoots) { Write-Error "No audit roots staged. Nothing to consolidate."; exit 1 }

    Write-Host ""; Write-Host "Staged audit roots:" -ForegroundColor Cyan
    $localAuditRoots | ForEach-Object { Write-Host "  $_" }

    $mergeDir = Join-Path $RepoRoot "FLEET_MERGE"
    Ensure-Dir $mergeDir

    Write-Host ""; Write-Host "=== RUNNING CONSOLIDATION ===" -ForegroundColor Cyan
    $consolidateScript = Join-Path $RepoRoot "scripts\Consolidate-AuditFleet.ps1"
    if (-not (Test-Path $consolidateScript)) { Write-Error "Consolidate-AuditFleet.ps1 not found at $consolidateScript"; exit 1 }

    & $consolidateScript -AuditRoots $localAuditRoots -CanonicalReposRoot (Join-Path $env:USERPROFILE "source\repos") -OutDir $mergeDir

    Write-Host ""; Write-Host "=== GENERATING SAFE CUT LIST ===" -ForegroundColor Cyan
    $safeCutScript = Join-Path $RepoRoot "scripts\Generate-SafeCutList.ps1"
    if (-not (Test-Path $safeCutScript)) { Write-Error "Generate-SafeCutList.ps1 not found at $safeCutScript"; exit 1 }

    & $safeCutScript -MergeDir $mergeDir

    $ledgerPath = Join-Path $mergeDir "Fleet_HistoricalIP_Ledger.csv"
    $safePath   = Join-Path $mergeDir "Fleet_SafeCutList.csv"

    Write-Host ""; Write-Host "=== FLEET AUDIT COMPLETE ===" -ForegroundColor Green
    Write-Host "Ledger        : $ledgerPath"
    Write-Host "Safe Cut List : $safePath"

    if (Test-Path $safePath) {
        $rows = Import-Csv $safePath
        $total = $rows.Count
        $safe  = ($rows | Where-Object { $_.SafeToDelete -eq 'True' }).Count
        Write-Host ("Rows in SafeCut : {0} (SafeToDelete = True: {1})" -f $total, $safe) -ForegroundColor Yellow
    } else { Write-Warning "SafeCut CSV not found – check previous output." }
}

# -------------------------------------------------------------------------
# ENTRYPOINT DISPATCH
# -------------------------------------------------------------------------
if ($SnapshotOnly -and $FullFleet) { Write-Error 'Choose either -SnapshotOnly or -FullFleet, not both.'; exit 1 }
if ($SnapshotOnly) { Invoke-EmergencySnapshot -NodeName $NodeName -SnapshotRootParent $SnapshotRootParent; exit 0 }
if ($FullFleet)    { Invoke-FullFleetAudit -AuditInputRoot $AuditInputRoot -RepoRoot $RepoRoot -Nodes $Nodes; exit 0 }
Write-Host 'No mode specified. Use one of:' -ForegroundColor Yellow
Write-Host '  .\scripts\RUN-SovereignFleet.ps1 -SnapshotOnly'
Write-Host '  .\scripts\RUN-SovereignFleet.ps1 -FullFleet'
exit 1
