param(
  [string]$ClientIp = '127.0.0.1',
  [string]$Command = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Config {
  $cfgPath = Join-Path $PSScriptRoot 'config.json'
  if (-not (Test-Path -LiteralPath $cfgPath)) { throw "Config file not found: $cfgPath" }
  (Get-Content -Raw -LiteralPath $cfgPath | ConvertFrom-Json)
}

function Write-Log {
  param([string]$Message, [string]$Category = 'INFO')
  $cfg = Read-Config
  $logDir = $cfg.LogRoot
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  $ts = (Get-Date).ToString('s')
  $line = "[$ts][$Category] $Message"
  Add-Content -LiteralPath (Join-Path $logDir 'access.log') -Value $line
}

function Get-RecentBiometricApproval {
  param([int]$WindowMinutes)
  $cfg = Read-Config
  $path = $cfg.BiometricLogPath
  if (-not (Test-Path -LiteralPath $path)) { return $false }
  $threshold = (Get-Date).AddMinutes(-$WindowMinutes)
  $lines = Get-Content -LiteralPath $path -ErrorAction SilentlyContinue | Select-Object -Last 200
  foreach ($line in $lines) {
    if ($line -match 'Approved' -and $line -match ("{0:yyyy-MM-dd}" -f (Get-Date))) {
      # naive time window check: accept recent entries (improve if log has timestamps)
      return $true
    }
  }
  return $false
}

function Test-PhysicalPresence {
  $cfg = Read-Config
  return (Get-RecentBiometricApproval -WindowMinutes $cfg.PhysicalPresenceWindowMinutes)
}

function Test-SovereignAccess {
  param([string]$ClientIP, [string]$Command)
  $cfg = Read-Config

  if ($cfg.AllowedLoopbackOnly -and $ClientIP -ne '127.0.0.1') {
    Write-Log "ACCESS VIOLATION: $ClientIP attempted direct connection" 'SECURITY'
    return $false
  }

  # Optional: client TLS certificate pinning
  if ($cfg.AllowedClientThumbprints -and $cfg.AllowedClientThumbprints.Count -gt 0) {
    try {
      # Placeholder: In pure HttpListener mode, client cert is available per request.
      # The caller should pass the thumbprint when integrating with the server.
      if (-not $script:ClientCertThumbprint) {
        Write-Log "CERT VIOLATION: No client certificate provided" 'SECURITY'
        return $false
      }
      if (-not ($cfg.AllowedClientThumbprints -contains $script:ClientCertThumbprint)) {
        Write-Log "CERT VIOLATION: $script:ClientCertThumbprint not authorized" 'SECURITY'
        return $false
      }
    } catch {
      Write-Log "CERT CHECK ERROR: $_" 'ERROR'
      return $false
    }
  }

  if ($Command -and ($cfg.CriticalCommands -contains $Command)) {
    if (-not (Test-PhysicalPresence)) {
      Write-Log "PHYSICAL VIOLATION: Critical command without presence" 'SECURITY'
      return $false
    }
  }
  return $true
}

if ($MyInvocation.InvocationName -ne '.') {
  if (Test-SovereignAccess -ClientIP $ClientIp -Command $Command) { Write-Output $true } else { Write-Output $false }
}
