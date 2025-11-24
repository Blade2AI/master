[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Targets,
    [int]$MaxPCs = 5,
    [string]$OutputRoot = "Data/vscode_audit",
    [switch]$IncludeSnippets
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-Dir([string]$Path) { if (-not [string]::IsNullOrWhiteSpace($Path)) { New-Item -ItemType Directory -Force -Path $Path | Out-Null } }
function Compute-Hash([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }

$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$workspaceRoot = (Split-Path -Parent $PSScriptRoot)
$absOutRoot = Join-Path $workspaceRoot $OutputRoot
New-Dir $absOutRoot
$outSession = Join-Path $absOutRoot "session_$ts"
New-Dir $outSession

$targetsList = @()
if ($Targets) {
    $targetsList = $Targets.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}
if ($MaxPCs -gt 0 -and $targetsList.Count -gt $MaxPCs) { $targetsList = $targetsList | Select-Object -First $MaxPCs }

Write-Host "Targets: $($targetsList -join ', ')" -ForegroundColor Cyan

$audit = @()

foreach ($pc in $targetsList) {
    $pcFolder = Join-Path $outSession $pc
    New-Dir $pcFolder
    $usersPath = "\\$pc\C$\Users"
    try {
        $userDirs = Get-ChildItem -LiteralPath $usersPath -Directory -ErrorAction Stop | Where-Object { $_.Name -notin @('Public','Default','Default User','All Users') }
    } catch {
        $audit += [pscustomobject]@{ pc=$pc; status='unreachable'; error=$_.Exception.Message }
        Write-Warning "Unable to enumerate users on $pc: $($_.Exception.Message)"
        continue
    }

    foreach ($ud in $userDirs) {
        $userName = $ud.Name
        $userOut = Join-Path $pcFolder $userName
        New-Dir $userOut
        $reports = @()
        $settingsPath = Join-Path $ud.FullName "AppData\Roaming\Code\User\settings.json"
        $keybindingsPath = Join-Path $ud.FullName "AppData\Roaming\Code\User\keybindings.json"
        $snippetsPath = Join-Path $ud.FullName "AppData\Roaming\Code\User\snippets"
        $extDir = Join-Path $ud.FullName ".vscode\extensions"

        $settingsOut = $null; $keybindingsOut = $null; $extensionsOut = $null

        if (Test-Path -LiteralPath $settingsPath) { $settingsOut = Join-Path $userOut 'settings.json'; Copy-Item -LiteralPath $settingsPath -Destination $settingsOut -Force }
        if (Test-Path -LiteralPath $keybindingsPath) { $keybindingsOut = Join-Path $userOut 'keybindings.json'; Copy-Item -LiteralPath $keybindingsPath -Destination $keybindingsOut -Force }
        if ($IncludeSnippets -and (Test-Path -LiteralPath $snippetsPath)) { Copy-Item -LiteralPath $snippetsPath -Destination (Join-Path $userOut 'snippets') -Recurse -Force }
        $extList = @()
        if (Test-Path -LiteralPath $extDir) {
            $extList = Get-ChildItem -LiteralPath $extDir -Directory | Select-Object -ExpandProperty Name | Sort-Object
        }
        if ($extList.Count -gt 0) { $extensionsOut = Join-Path $userOut 'extensions.txt'; ($extList -join "`n") | Set-Content -LiteralPath $extensionsOut -Encoding UTF8 }

        $audit += [pscustomobject]@{
            pc = $pc
            user = $userName
            settings_present = [bool](Test-Path $settingsOut)
            settings_sha256 = if (Test-Path $settingsOut) { Compute-Hash $settingsOut } else { $null }
            keybindings_present = [bool](Test-Path $keybindingsOut)
            keybindings_sha256 = if (Test-Path $keybindingsOut) { Compute-Hash $keybindingsOut } else { $null }
            extensions_count = $extList.Count
        }
    }
}

# Write summary artifacts
$summaryJson = Join-Path $outSession 'summary.json'
($audit | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $summaryJson -Encoding UTF8

$summaryMd = Join-Path $outSession 'SUMMARY.md'
$md = @()
$md += "# VS Code Fleet Review ($ts)"
$md += ""
$md += "Targets: $($targetsList -join ', ')"
$md += ""
$grouped = $audit | Group-Object pc | Sort-Object Name
foreach ($g in $grouped) {
    $md += "## $($g.Name)"
    foreach ($row in ($g.Group | Sort-Object user)) {
        $md += "- $($row.user): settings=$($row.settings_present) kb=$($row.keybindings_present) ext=$($row.extensions_count)"
    }
    $md += ""
}
$md | Set-Content -LiteralPath $summaryMd -Encoding UTF8

Write-Host "Fleet review complete: $summaryMd" -ForegroundColor Green
