[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Targets,          # comma/semicolon/space separated
  [Parameter(Mandatory=$true)][string]$RepoPath,         # repo root on remote machine (e.g., Z:\Forge\apps\master)
  [int]$MonteCarloN = 1000,
  [string]$PythonPath,                                   # optional explicit python path dir on remote
  [switch]$PromptForCredential
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err ($m){ Write-Host "[FAIL] $m" -ForegroundColor Red }

$computers = @()
($Targets -split '[,;\s]+' | Where-Object { $_ -and $_.Trim().Length -gt 0 }) | ForEach-Object { $computers += $_.Trim() }
if ($computers.Count -eq 0) { throw "No valid targets provided." }

$cred = $null
if ($PromptForCredential) { $cred = Get-Credential -Message "Credentials for remote run" }

$results = @()

$scriptBlock = {
  param($repo,$mc,$py)
  $ErrorActionPreference = 'Stop'
  if ($py -and (Test-Path -LiteralPath $py)) { $env:Path = "$py;$env:Path" }
  $runner = Join-Path $repo 'scripts/Run-Empathy-Tests.ps1'
  if (-not (Test-Path -LiteralPath $runner)) { throw "Runner script not found: $runner" }
  & powershell -NoProfile -ExecutionPolicy Bypass -File $runner -MonteCarloN $mc
}

foreach ($c in $computers) {
  try {
    Write-Info "Running empathy tests on $c"
    if ($cred) {
      $out = Invoke-Command -ComputerName $c -Credential $cred -ScriptBlock $scriptBlock -ArgumentList $RepoPath,$MonteCarloN,$PythonPath -ErrorAction Stop | Out-String
    } else {
      $out = Invoke-Command -ComputerName $c -ScriptBlock $scriptBlock -ArgumentList $RepoPath,$MonteCarloN,$PythonPath -ErrorAction Stop | Out-String
    }
    Write-Host $out
    $results += [pscustomobject]@{ Computer=$c; Ok=$true }
  }
  catch {
    Write-Err "${c}: $($_.Exception.Message)"
    $results += [pscustomobject]@{ Computer=$c; Ok=$false; Error=$_.Exception.Message }
  }
}

Write-Host "=== Summary ===" -ForegroundColor Green
$results | ForEach-Object { if ($_.Ok) { Write-Host ("  {0}: OK" -f $_.Computer) -ForegroundColor Green } else { Write-Host ("  {0}: FAIL - {1}" -f $_.Computer, $_.Error) -ForegroundColor Red } }
