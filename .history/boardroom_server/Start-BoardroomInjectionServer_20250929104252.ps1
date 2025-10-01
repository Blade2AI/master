param(
  [int]$Port = 8444
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

.$PSScriptRoot\verify_access.ps1

function Read-Config { (Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'config.json') | ConvertFrom-Json) }

function Read-BodyJson($ctx) {
  $stream = $ctx.Request.InputStream
  $enc = [System.Text.Encoding]::UTF8
  $reader = New-Object System.IO.StreamReader($stream, $enc)
  $text = $reader.ReadToEnd()
  if (-not $text) { return $null }
  return ($text | ConvertFrom-Json)
}

function Send-Json($ctx, $obj, [int]$code=200) {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes(($obj | ConvertTo-Json -Depth 6))
  $ctx.Response.ContentType = 'application/json'
  $ctx.Response.StatusCode = $code
  $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $ctx.Response.OutputStream.Close()
}

function Initialize-BoardroomQueueFile {
  $cfg = Read-Config
  New-Item -ItemType Directory -Path (Split-Path -Parent $cfg.IdeaQueueFile) -Force | Out-Null
  if (-not (Test-Path -LiteralPath $cfg.IdeaQueueFile)) { '[]' | Set-Content -LiteralPath $cfg.IdeaQueueFile -Encoding UTF8 }
}

function Measure-BoardroomImpact([string]$text) {
  if ($text -match '(?i)leak|energy') { return 15000 }
  return 5000
}

function Add-ToQueue($obj) {
  $cfg = Read-Config
  Initialize-BoardroomQueueFile
  $retries = 0
  while ($true) {
    try {
      $json = Get-Content -Raw -LiteralPath $cfg.IdeaQueueFile | ConvertFrom-Json
      $arr = @()
      if ($json -is [System.Array]) { $arr = @($json) } elseif ($json) { $arr = @($json) }
      $arr += $obj
      ($arr | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $cfg.IdeaQueueFile -Encoding UTF8
      return $true
    } catch {
      Start-Sleep -Milliseconds 100
      $retries++
      if ($retries -gt 20) { throw }
    }
  }
}

function Start-Listener([int]$Port) {
  $prefix = "https://+:$Port/"
  $listener = [System.Net.HttpListener]::new()
  $listener.Prefixes.Add($prefix)
  $listener.Start()
  Write-Host "Idea Injection HTTPS server on $prefix" -ForegroundColor Green
  return $listener
}

$listener = Start-Listener -Port $Port
while ($true) {
  $ctx = $listener.GetContext()
  try {
    $clientIp = $ctx.Request.RemoteEndPoint.Address.ToString()
    if ($ctx.Request.IsSecureConnection -and $ctx.Request.ClientCertificate) {
      $script:ClientCertThumbprint = $ctx.Request.ClientCertificate.GetCertHashString()
    } else { $script:ClientCertThumbprint = $null }
    if (-not (Test-SovereignAccess -ClientIP $clientIp -Command 'inject')) { Send-Json $ctx @{ error='forbidden' } 403; continue }

    if ($ctx.Request.HttpMethod -eq 'POST' -and $ctx.Request.Url.AbsolutePath.ToLowerInvariant() -eq '/inject') {
      $body = Read-BodyJson $ctx
      if (-not $body -or -not $body.Text) { Send-Json $ctx @{ error='invalid_payload' } 400; continue }
  $impact = Measure-BoardroomImpact ([string]$body.Text)
      $item = [ordered]@{
        Text = [string]$body.Text
        Timestamp = (Get-Date).ToString('s')
        Injector = if ($body.Injector) { [string]$body.Injector } else { 'unknown' }
        ImpactEstimate = $impact
      }
      Add-ToQueue -obj $item | Out-Null
      Send-Json $ctx @{ status='Queued'; impact_est = ("£{0:N0}" -f $impact); pause = 'Biometric if >£10k' } 202
      continue
    }

    Send-Json $ctx @{ error='not_found' } 404
  } catch {
    try { Send-Json $ctx @{ error='server_error'; detail = ("{0}" -f $_) } 500 } catch {}
  }
}
