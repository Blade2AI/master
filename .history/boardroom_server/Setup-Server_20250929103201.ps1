param(
  [string]$CertCN = 'Boardroom-Local',
  [string]$Subnet = '192.168.10.0/24',
  [switch]$NoSsh
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-BoardroomSelfSignedCertificate([string]$cn) {
  $cert = New-SelfSignedCertificate -DnsName $cn -CertStoreLocation Cert:\LocalMachine\My -KeyAlgorithm RSA -KeyLength 2048 -NotAfter (Get-Date).AddYears(2)
  return $cert
}

function Set-BoardroomHttpSysCertificate([int]$port, [string]$thumbprint) {
  $appId = '{7e1f7c4b-4c7d-47f1-bd6d-2e1c4f32a7aa}'
  & netsh http delete sslcert ipport=0.0.0.0:$port 2>$null | Out-Null
  & netsh http add sslcert ipport=0.0.0.0:$port certhash=$thumbprint appid=$appId certstore=MY | Out-Null
}

function Add-BoardroomFirewallRule([int]$port, [string]$name) {
  if (-not (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName $name -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port | Out-Null
  }
}

Write-Host 'Setting up Boardroom server prerequisites...' -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path 'C:\ProgramData\Boardroom\wwwroot' | Out-Null
Copy-Item -Path (Join-Path $PSScriptRoot 'wwwroot\index.html') -Destination 'C:\ProgramData\Boardroom\wwwroot\index.html' -Force

if (-not $NoSsh) {
  Write-Host 'Installing OpenSSH Server feature if missing...' -ForegroundColor Yellow
  Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0' -ErrorAction SilentlyContinue | Out-Null
  Start-Service sshd; Set-Service -Name sshd -StartupType Automatic
}

Write-Host 'Creating/binding self-signed certificates to 443 and 8444...' -ForegroundColor Yellow
$cert = New-BoardroomSelfSignedCertificate -cn $CertCN
Set-BoardroomHttpSysCertificate -port 443 -thumbprint $cert.Thumbprint
Set-BoardroomHttpSysCertificate -port 8444 -thumbprint $cert.Thumbprint

Add-BoardroomFirewallRule -port 443 -name 'Boardroom HTTPS 443'
Add-BoardroomFirewallRule -port 8444 -name 'Boardroom Injection 8444'

Write-Host 'Scheduling 15-min pulse task...' -ForegroundColor Yellow
$taskName = 'BoardroomPulse'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSScriptRoot\\Update-BoardroomPulse.ps1`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration ([TimeSpan]::MaxValue)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null

Write-Host 'Setup complete.' -ForegroundColor Green
