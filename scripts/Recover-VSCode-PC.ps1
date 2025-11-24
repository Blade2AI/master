[CmdletBinding()]
param(
    [switch]$AutoInstall,
    [string]$ConfigSource,       # Path containing settings.json/keybindings.json/snippets
    [string]$ExtensionsList,     # Path to a file with extension IDs (one per line)
    [switch]$SkipWindowReset,
    [switch]$SkipBackupsCopy
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Paths -------------------------------------------------------------
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$ws = (Split-Path -Parent $PSScriptRoot)
$recoveryRoot = Join-Path $ws 'Data/vscode_recovery'
$null = New-Item -ItemType Directory -Force -Path $recoveryRoot -ErrorAction SilentlyContinue
$logPath = Join-Path $recoveryRoot "recovery_$ts.log"

function Log([string]$msg,[string]$level='INFO') {
    $line = "[$(Get-Date -Format o)] [$level] $msg"
    Write-Host $line
    Add-Content -LiteralPath $logPath -Value $line
}

$AppDataCode = Join-Path $env:APPDATA 'Code'
$UserDir = Join-Path $AppDataCode 'User'
$GlobalStorage = Join-Path $UserDir 'globalStorage'
$StateDb = Join-Path $GlobalStorage 'state.vscdb'
$BackupsDir = Join-Path $AppDataCode 'Backups'

# 1) Stop any running VS Code processes -----------------------------
try {
    Get-Process -Name 'Code' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-Process -Name 'code' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Log 'Stopped running VS Code processes if any.'
} catch { Log $_.Exception.Message 'WARN' }

# 2) Detect installation --------------------------------------------
$codeExeCandidates = @(
    Join-Path $env:LOCALAPPDATA 'Programs/Microsoft VS Code/Code.exe'),
    Join-Path $env:ProgramFiles 'Microsoft VS Code/Code.exe'),
    Join-Path ${env:ProgramFiles(x86)} 'Microsoft VS Code/Code.exe')
$CodeExe = $codeExeCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if (-not $CodeExe -and $AutoInstall) {
    Log 'VS Code not found. AutoInstall enabled; downloading installer.' 'WARN'
    $installerUrl = 'https://update.code.visualstudio.com/latest/win32-x64-user/stable'
    $installer = Join-Path $env:TEMP "VSCodeSetup-$ts.exe"
    Invoke-WebRequest -Uri $installerUrl -OutFile $installer -UseBasicParsing
    Start-Process -FilePath $installer -ArgumentList '/VERYSILENT','/NORESTART','/MERGETASKS=!runcode' -Wait
    Start-Sleep -Seconds 3
    $CodeExe = $codeExeCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $CodeExe) { throw 'VS Code install failed or path not found after install.' }
    Log "VS Code installed: $CodeExe"
}
elseif ($CodeExe) {
    Log "VS Code found: $CodeExe"
}
else {
    Log 'VS Code not found and AutoInstall is disabled. Exiting early.' 'ERROR'
    exit 1
}

# 3) Reset window state (fix invisible window) ----------------------
if (-not $SkipWindowReset) {
    if (Test-Path -LiteralPath $StateDb) {
        $bak = "$StateDb.$ts.bak"
        Rename-Item -LiteralPath $StateDb -NewName $bak -Force
        Log "Window state DB moved to: $bak"
    } else {
        Log 'No window state DB found to reset (ok).'
    }
}

# 4) Copy unsaved backups to workspace safety-net -------------------
if (-not $SkipBackupsCopy) {
    if (Test-Path -LiteralPath $BackupsDir) {
        $dest = Join-Path $recoveryRoot "Backups_$ts"
        robocopy $BackupsDir $dest /E | Out-Null
        Log "Backups copied to: $dest"
    } else {
        Log 'No Backups directory found (ok).'
    }
}

# 5) Restore settings/keybindings/snippets from source --------------
if ($ConfigSource) {
    if (-not (Test-Path -LiteralPath $ConfigSource)) { throw "ConfigSource not found: $ConfigSource" }
    $settingsSrc   = Join-Path $ConfigSource 'settings.json'
    $keybindsSrc   = Join-Path $ConfigSource 'keybindings.json'
    $snippetsSrc   = Join-Path $ConfigSource 'snippets'

    $null = New-Item -ItemType Directory -Force -Path $UserDir -ErrorAction SilentlyContinue

    if (Test-Path -LiteralPath $settingsSrc) { Copy-Item -LiteralPath $settingsSrc -Destination (Join-Path $UserDir 'settings.json') -Force; Log 'settings.json restored.' }
    if (Test-Path -LiteralPath $keybindsSrc) { Copy-Item -LiteralPath $keybindsSrc -Destination (Join-Path $UserDir 'keybindings.json') -Force; Log 'keybindings.json restored.' }
    if (Test-Path -LiteralPath $snippetsSrc) { robocopy $snippetsSrc (Join-Path $UserDir 'snippets') /E | Out-Null; Log 'snippets restored.' }
}

# 6) Reinstall extensions from list ---------------------------------
if ($ExtensionsList -and (Test-Path -LiteralPath $ExtensionsList)) {
    # Prefer code.cmd if present
    $codeCmdCandidates = @(
        Join-Path (Split-Path -Parent $CodeExe) 'bin\code.cmd',
        (Get-Command 'code' -ErrorAction SilentlyContinue)?.Source
    )
    $codeCmd = $codeCmdCandidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
    if (-not $codeCmd) { $codeCmd = $CodeExe }

    Get-Content -LiteralPath $ExtensionsList | ForEach-Object {
        $id = $_.Trim()
        if ($id -and -not $id.StartsWith('#')) {
            Log "Installing extension: $id"
            try {
                & $codeCmd --install-extension $id --force | Out-Null
            } catch { Log "Failed to install $id: $($_.Exception.Message)" 'WARN' }
        }
    }
}

# 7) Launch VS Code --------------------------------------------------
try {
    Start-Process -FilePath $CodeExe -ArgumentList @('--reuse-window') | Out-Null
    Log 'VS Code launched.'
} catch { Log $_.Exception.Message 'WARN' }

Log "Recovery complete. Log saved at $logPath"
