param(
  [string]$LocalGlob = "C:\\ops\\logs\\*.jsonl",
  [string]$NasLogDir = "\\\dxp4800plus-67ba\\ops\\logs",
  [int]$DaysToKeep = 14
)

function Write-Line($msg){ Write-Host ("[{0:u}] {1}" -f (Get-Date), $msg) }

# Ensure NAS path exists
try { New-Item -ItemType Directory -Force -Path $NasLogDir | Out-Null } catch {}

$hostName = $env:COMPUTERNAME
$destDir = Join-Path $NasLogDir $hostName
New-Item -ItemType Directory -Force -Path $destDir | Out-Null

# Copy new/updated logs
Get-ChildItem -Path $LocalGlob -ErrorAction SilentlyContinue | ForEach-Object {
  $dest = Join-Path $destDir $_.Name
  try {
    Copy-Item -Path $_.FullName -Destination $dest -Force
    Write-Line "shipped: $($_.Name)"
  } catch { Write-Line "ship-failed: $($_.Name) :: $_" }
}

# Optional cleanup: delete local logs older than N days
Get-ChildItem -Path (Split-Path $LocalGlob) -Filter *.jsonl -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysToKeep) } | ForEach-Object {
  try { Remove-Item -Path $_.FullName -Force } catch {}
}
