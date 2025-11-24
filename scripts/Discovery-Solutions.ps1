param(
  [string]$Root = "C:\vs-studio-projects"
)
Write-Host "=== Solution Discovery ===" -ForegroundColor Cyan
Get-ChildItem -Path $Root -Recurse -Filter *.sln -ErrorAction SilentlyContinue | ForEach-Object {
  [PSCustomObject]@{Solution=$_.FullName}
} | Format-Table -AutoSize
