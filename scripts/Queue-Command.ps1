param(
  [string[]]$Hosts,
  [ValidateSet('deploy','run','sync','ps')]$Type='run',
  [string]$QueueRoot = "\\dxp4800plus-67ba\ops\Queue",
  [string]$Package = '',
  [string]$Dest = 'C:\\ops',
  [string]$Script = '',
  [string[]]$Args,
  [string]$Code
)

if (-not $Hosts -or $Hosts.Count -eq 0) { throw 'Specify -Hosts list' }

# Auto-switch to ps if -Code was provided
if ($Code) { $Type = 'ps' }

$cmd = [ordered]@{ id=[guid]::NewGuid().ToString(); type=$Type }
if ($Type -eq 'deploy') { $cmd.package=$Package; $cmd.dest=$Dest }
elseif ($Type -eq 'sync') { $cmd.source=$Package; $cmd.dest=$Dest }
elseif ($Type -eq 'ps') { $cmd.code=$Code }
else { $cmd.script=$Script; if ($Args){$cmd.args=$Args} }

foreach ($h in $Hosts) {
  $dir = Join-Path $QueueRoot ($h.ToLower())
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $file = Join-Path $dir ("command_" + $cmd.id + ".json")
  ($cmd | ConvertTo-Json -Depth 8) | Set-Content -Encoding UTF8 $file
  Write-Host "Queued $($cmd.type) for $h (id=$($cmd.id)) -> $file"
}
