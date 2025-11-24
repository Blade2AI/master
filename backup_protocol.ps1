# SOVEREIGN MIRROR PROTOCOL
param(
  [string]$Source = "C:\Users\andyj\AI_Agent_Research",
  [string]$DestPC3 = "D:\Sovereign_Backups",
  [string]$DestPC4 = "E:\Sovereign_Backups"
)

$opts = @("/MIR", "/FFT", "/R:3", "/W:5", "/XD", ".venv", "__pycache__", ".git")

Write-Host "?? MIRRORING TO PC3..." -ForegroundColor Cyan
robocopy $Source $DestPC3 @opts

Write-Host "?? MIRRORING TO PC4..." -ForegroundColor Cyan
robocopy $Source $DestPC4 @opts

Write-Host "? SECURE." -ForegroundColor Green
