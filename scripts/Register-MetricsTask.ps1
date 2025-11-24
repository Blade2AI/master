[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$TaskName = 'Sovereign – Manage Metrics',
  [string]$RepoRoot = 'C:\Users\andyj\source\repos\PrecisePointway\master',
  [string]$ConfigPath = 'C:\Users\andyj\source\repos\PrecisePointway\master\config\metrics_config.yaml',
  [ValidateSet('PT15M','PT30M','PT1H')][string]$Every = 'PT30M', # ISO8601 for Scheduled Task repetition
  [switch]$RunAsSystem
)
$ErrorActionPreference='Stop'

$scriptPath = Join-Path $RepoRoot 'scripts\Manage-Metrics.ps1'
if(-not (Test-Path $scriptPath)){ throw "Manage-Metrics.ps1 not found: $scriptPath" }
if(-not (Test-Path $ConfigPath)){ throw "Metrics config not found: $ConfigPath" }

$arguments = @('-NoLogo','-NonInteractive','-File',"`"$scriptPath`"",'-ConfigPath',"`"$ConfigPath`"" ) -join ' '
$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument $arguments -WorkingDirectory $RepoRoot
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddMinutes(2) -RepetitionDuration ([TimeSpan]::MaxValue) -RepetitionInterval ([System.Xml.XmlConvert]::ToTimeSpan($Every))
if($RunAsSystem){ $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest }
else { $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType InteractiveToken -RunLevel Highest }
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Description 'Rotate, aggregate, and integrity-log Sovereign metrics.'
if($PSCmdlet.ShouldProcess($TaskName,'Register-ScheduledTask')){
  Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force
  Write-Host "[OK] Scheduled task registered: $TaskName (Interval=$Every System=$RunAsSystem)" -ForegroundColor Green
  Write-Host "To run now: Start-ScheduledTask -TaskName \"$TaskName\"" -ForegroundColor Cyan
}
