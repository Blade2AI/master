param(
  [Parameter(Mandatory)] [string]$WorkspacePath,
  [Parameter(Mandatory)] [string]$Message
)

Set-Location $WorkspacePath

git add .
try { git commit -m $Message | Out-Host } catch { Write-Host "Nothing to commit or commit failed: $_" -ForegroundColor Yellow }
try { git push | Out-Host } catch { Write-Host "git push failed: $_" -ForegroundColor Yellow }
