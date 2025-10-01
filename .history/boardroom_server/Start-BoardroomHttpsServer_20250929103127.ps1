param(
  [int]$Port = 443
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

.$PSScriptRoot\verify_access.ps1

function Read-Config { (Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'config.json') | ConvertFrom-Json) }

function Get-Status {
  $cfg = Read-Config
  $path = $cfg.StatusFile
  if (-not (Test-Path -LiteralPath $path)) {
    return @{ pulse = 'initializing'; risk_level = 'Unknown'; financial_impact = '£0/min' }
  }
  try { (Get-Content -Raw -LiteralPath $path | ConvertFrom-Json) } catch { @{ error = 'status_read_error' } }
}

function Send-Json($ctx, $obj, [int]$code=200) {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes(($obj | ConvertTo-Json -Depth 6))
  $ctx.Response.ContentType = 'application/json'
  $ctx.Response.StatusCode = $code
  $ctx.Response.ContentEncoding = [System.Text.Encoding]::UTF8
  $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $ctx.Response.OutputStream.Close()
}

function Send-File($ctx, [string]$path) {
  $bytes = [System.IO.File]::ReadAllBytes($path)
  $ctx.Response.ContentType = 'text/html; charset=utf-8'
  $ctx.Response.StatusCode = 200
  $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $ctx.Response.OutputStream.Close()
}

function Start-Listener {
  param([int]$Port)
  $prefix = "https://+:$Port/"
  $listener = [System.Net.HttpListener]::new()
  $listener.Prefixes.Add($prefix)
  $listener.Start()
  Write-Host "Boardroom HTTPS server listening on $prefix" -ForegroundColor Green
  return $listener
}

function Add-BoardroomFirewallRule([int]$Port) {
  if (-not (Get-NetFirewallRule -DisplayName "Boardroom HTTPS $Port" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "Boardroom HTTPS $Port" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port | Out-Null
  }
}

Add-BoardroomFirewallRule -Port $Port
$listener = Start-Listener -Port $Port

while ($true) {
  $context = $listener.GetContext()
  try {
    $clientIp = $context.Request.RemoteEndPoint.Address.ToString()
    $path = $context.Request.Url.AbsolutePath.ToLowerInvariant()

    if (-not (Test-SovereignAccess -ClientIP $clientIp -Command '')) {
      Send-Json $context @{ error = 'forbidden' } 403
      continue
    }

    if ($path -eq '/status') {
      $status = Get-Status
      Send-Json $context $status 200
      continue
    }

    if ($path -eq '/' -or $path -eq '/index.html') {
      $cfg = Read-Config
      $indexPath = Join-Path $cfg.DashboardRoot 'index.html'
      if (-not (Test-Path -LiteralPath $indexPath)) { Send-Json $context @{ error='no_index' } 404; continue }
      Send-File $context $indexPath
      continue
    }

    Send-Json $context @{ error = 'not_found' } 404
  } catch {
    try { Send-Json $context @{ error = 'server_error'; detail = ("{0}" -f $_) } 500 } catch {}
  }
}
