# Fleet configuration - edit once, deploy everywhere
$Global:OpsRoot   = "\\dxp4800plus-67ba\ops"
$Global:Payload   = Join-Path $OpsRoot "payload"
$Global:LogsRoot  = Join-Path $OpsRoot "logs"
$Global:FleetRoot = Join-Path $OpsRoot "fleet"
$Global:PcList    = Get-Content (Join-Path $FleetRoot "pc-list.txt") | Where-Object {$_ -and $_ -notmatch '^\s*#'}
$Global:UserHome  = "C:\Users\Public"
$Global:VSUserDir = "$env:USERPROFILE\AppData\Roaming\Code\User"

# Ensure required directories exist
New-Item -ItemType Directory -Force $LogsRoot | Out-Null
New-Item -ItemType Directory -Force $Payload | Out-Null
New-Item -ItemType Directory -Force $FleetRoot | Out-Null

# Collaboration motto for all operations
$Global:Motto = "?? In a world you can be anything – be nice."

# C++14 development settings
$Global:CppStandard = "c++14"
$Global:WorkspaceRepo = "https://github.com/PrecisePointway/master"

# Network optimization settings
$Global:LiveSharePorts = @(40000..40100)
$Global:LatencyThresholds = @{
    Excellent = 5
    Good = 15
    Fair = 50
}

Write-Host $Global:Motto -ForegroundColor Magenta