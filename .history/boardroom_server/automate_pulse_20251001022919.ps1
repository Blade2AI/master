Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Config { (Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'config.json') | ConvertFrom-Json) }
function Write-VaultLog([string]$message, [string]$category='INFO') {
  $cfg = Read-Config
  $dir = $cfg.LogRoot; New-Item -ItemType Directory -Path $dir -Force | Out-Null
  $ts = (Get-Date).ToString('s')
  Add-Content -LiteralPath (Join-Path $dir 'automation.log') -Value "[$ts][$category] $message"
}

function Measure-BoardroomImpact([string]$text) { if ($text -match '(?i)leak|energy') { 15000 } else { 5000 } }

function Convert-BoardroomIdeaToAction([string]$text) {
  if ($text -match '(?i)co-?op\s*(?<type>\w+)?') {
    $t = $Matches['type']; if (-not $t) { $t = 'Energy' }
    return "New-CoOp -Type $t"
  }
  return ('Write-Output "IDEA:{0}"' -f ($text -replace '"','\"'))
}

function Test-PhysicalPresence { . $PSScriptRoot\verify_access.ps1; return (Test-PhysicalPresence) }

function Read-Queue { $cfg = Read-Config; if (Test-Path -LiteralPath $cfg.IdeaQueueFile) { (Get-Content -Raw -LiteralPath $cfg.IdeaQueueFile | ConvertFrom-Json) } else { @() } }
function Clear-Queue { $cfg = Read-Config; if (Test-Path -LiteralPath $cfg.IdeaQueueFile) { '[]' | Set-Content -LiteralPath $cfg.IdeaQueueFile -Encoding UTF8 } }

function Update-BoardroomStatus([int]$ideasProcessed) {
  $cfg = Read-Config
  $now = Get-Date
  $status = @{
    pulse = 'active'
    generated_at = $now.ToString('s')
    next_pulse_due = $now.AddMinutes(15).ToString('s')
    risk_level = 'Medium'
    financial_impact = '£4,852/min'
    ideas_processed = $ideasProcessed
    queue_size = (@(Read-Queue)).Count
  }
  ($status | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $cfg.StatusFile -Encoding UTF8
}

while ($true) {
  $ideas = @()
  try { $ideas = @(Read-Queue) } catch { Write-VaultLog "Queue read error: $_" 'ERROR' }
  $processed = 0
  foreach ($idea in $ideas) {
    try {
      $text = [string]$idea.Text
      $impact = if ($idea.PSObject.Properties['ImpactEstimate']) { [int]$idea.ImpactEstimate } else { Measure-BoardroomImpact $text }
      if ($impact -gt [int]$cfg.ImpactThreshold) {
        if (-not (Test-PhysicalPresence)) { Write-VaultLog "IDEA PAUSED: $text (£$impact) - Biometric Required" 'SECURITY'; continue }
      }
      $action = Convert-BoardroomIdeaToAction $text
      Write-VaultLog "EXECUTE: $action (from '$text' est £$impact)" 'ACTION'
      try { Invoke-Expression $action | Out-Null } catch { Write-VaultLog "Action error for '$action': $_" 'ERROR' }
      $processed++
    } catch { Write-VaultLog "Idea processing error: $_" 'ERROR' }
  }
  if ($ideas.Count -gt 0) { Clear-Queue }
  Update-BoardroomStatus -ideasProcessed $processed
  Start-Sleep -Seconds 900
}
