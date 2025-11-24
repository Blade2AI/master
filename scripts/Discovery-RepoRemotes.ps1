param(
  [string]$Root = "C:\vs-studio-projects",
  [string[]]$Repos = @('Precision','Pointway','Blade2AI')
)
Write-Host "=== Repo Remote Discovery ===" -ForegroundColor Cyan
foreach($r in $Repos){
  $path = Join-Path $Root $r
  if(Test-Path $path){
    Write-Host "`n==== $r ====" -ForegroundColor Yellow
    try { git -C $path ls-remote --get-url } catch { Write-Warning "Failed get-url for $r" }
    try { git -C $path ls-remote } catch { Write-Warning "Failed ls-remote for $r" }
  } else {
    Write-Warning "Repo path missing: $path"
  }
}
