param(
  [int]$Minutes = 15
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Config { (Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'config.json') | ConvertFrom-Json) }

$cfg = Read-Config
New-Item -ItemType Directory -Path (Split-Path -Parent $cfg.StatusFile) -Force | Out-Null

$now = Get-Date
$status = [ordered]@{
  pulse = 'active'
  generated_at = $now.ToString('s')
  next_pulse_due = $now.AddMinutes($Minutes).ToString('s')
  risk_level = 'Medium'
  financial_impact = '£4,852/min'
  panels = @(
    @{ name='Command Pulse'; details='15-min cycle status; Financial impact; Next action required' },
    @{ name='Risk Register Live'; details='5M model visualization; High-risk items; Auto-prioritized actions' },
    @{ name='Mistake Transmutation'; details='Errors → £ gains; Governance improvements; Real-time financial position' }
  )
}

($status | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $cfg.StatusFile -Encoding UTF8
