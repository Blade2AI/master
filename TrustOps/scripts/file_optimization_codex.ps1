<#!
File Optimization Codex (PowerShell 5.1)

Purpose:
 - Remove obvious junk safely via QUARANTINE first (No Lost Ideas Protocol)
 - Produce a manifest of actions (CSV + JSONL)
 - Never touch documents by default (.txt,.md,.pdf,.doc*,.ppt*,.xls*)

Usage examples:
  .\file_optimization_codex.ps1 -Target "C:\Users\User\Downloads" -DryRun
  .\file_optimization_codex.ps1 -Target . -Quarantine "C:\ProgramData\TrustOps\Quarantine" -RetentionDays 30 -Aggressive

Parameters:
  -Target <path>             Root to scan
  -Quarantine <path>         Where to move candidates (default ProgramData\TrustOps\Quarantine)
  -RetentionDays <int>       Days to retain quarantine before deletion (default 30; deletion not automated here)
  -Aggressive                Also capture build artifacts (bin/obj/dist/.cache) and large archives >1GB
  -IncludeDocuments          Allow moving documents (disabled by default)
  -DryRun                    Plan only, no moves

Manifest:
  Writes CSV + JSONL under <Quarantine>\_manifests\YYYYMMDD-HHMMSS.*
!#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
  [Parameter(Mandatory=$true)] [string]$Target,
  [string]$Quarantine,
  [int]$RetentionDays = 30,
  [switch]$Aggressive,
  [switch]$IncludeDocuments,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Note($m){ Write-Host "[codex] $m" }

function Resolve-PathSafe([string]$p){ (Resolve-Path -LiteralPath $p -ErrorAction Stop).Path }

function New-Dirs([string]$p){ if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null } }

function Get-CandidatePatterns([switch]$Agg){
  $base = @(
    '*.tmp','*.temp','*.bak','*.old','thumbs.db','.DS_Store','desktop.ini',
    '*.log'
  )
  if ($Agg) {
    $base += @('node_modules','dist','build','target','.cache','bin','obj')
  }
  return $base
}

function Is-Document($name){
  $docs = @('.txt','.md','.pdf','.doc','.docx','.ppt','.pptx','.xls','.xlsx')
  $ext = [System.IO.Path]::GetExtension($name).ToLowerInvariant()
  return $docs -contains $ext
}

function Enumerate-Candidates($root, $patterns, $includeDocs, $Agg){
  $items = @()
  foreach ($pat in $patterns) {
    if ($pat -in @('node_modules','dist','build','target','.cache','bin','obj')) {
      $dirs = Get-ChildItem -LiteralPath $root -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -ieq $pat }
      foreach ($d in $dirs) { $items += @{ Path=$d.FullName; Type='dir'; Reason="pattern:$pat" } }
    } else {
      $files = Get-ChildItem -LiteralPath $root -File -Recurse -Filter $pat -ErrorAction SilentlyContinue
      foreach ($f in $files) {
        if (-not $includeDocs -and (Is-Document $f.Name)) { continue }
        $items += @{ Path=$f.FullName; Type='file'; Reason="pattern:$pat" }
      }
    }
  }
  if ($Agg) {
    $big = Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 1GB -and -not (Is-Document $_.Name) }
    foreach ($b in $big) { $items += @{ Path=$b.FullName; Type='file'; Reason='large>1GB' } }
  }
  return $items
}

function Write-Manifests($rows, $outDir){
  $stamp = (Get-Date -Format 'yyyyMMdd-HHmmss')
  $manDir = Join-Path $outDir '_manifests'
  New-Dirs $manDir
  $csv = Join-Path $manDir ("manifest-$stamp.csv")
  $jsonl = Join-Path $manDir ("manifest-$stamp.jsonl")
  $rows | Export-Csv -NoTypeInformation -Path $csv -Encoding UTF8
  $sw = New-Object System.IO.StreamWriter($jsonl, $false, (New-Object System.Text.UTF8Encoding($false)))
  try { foreach ($r in $rows) { $sw.WriteLine((ConvertTo-Json $r -Depth 4 -Compress)) } } finally { $sw.Dispose() }
  return @{ Csv=$csv; Jsonl=$jsonl }
}

try {
  $root = Resolve-PathSafe $Target
  if (-not $Quarantine -or $Quarantine.Trim() -eq '') { $Quarantine = 'C:\ProgramData\TrustOps\Quarantine' }
  New-Dirs $Quarantine
  $patterns = Get-CandidatePatterns -Agg:$Aggressive
  Write-Note ("Scanning: {0}" -f $root)
  $cands = Enumerate-Candidates -root $root -patterns $patterns -includeDocs:$IncludeDocuments -Agg:$Aggressive
  $manifest = @()
  foreach ($c in $cands) {
    $rel = $c.Path.Substring($root.Length).TrimStart('\\')
    $dest = Join-Path $Quarantine $rel
    $manifest += [PSCustomObject]@{
      action = 'quarantine'
      path = $c.Path
      dest = $dest
      type = $c.Type
      reason = $c.Reason
      timestamp = (Get-Date).ToString('s')
    }
  }
  $outs = Write-Manifests -rows $manifest -outDir $Quarantine
  Write-Note ("Manifest written: {0} | {1}" -f $outs.Csv, $outs.Jsonl)

  if ($DryRun) { Write-Note 'DryRun: no moves performed.'; exit 0 }

  foreach ($row in $manifest) {
    $destDir = Split-Path -Parent $row.dest
    New-Dirs $destDir
    if ($row.type -eq 'dir') {
      if ($PSCmdlet.ShouldProcess($row.path, 'Move-Item (dir)')) { Move-Item -LiteralPath $row.path -Destination $row.dest -Force }
    } else {
      if ($PSCmdlet.ShouldProcess($row.path, 'Move-Item (file)')) { Move-Item -LiteralPath $row.path -Destination $row.dest -Force }
    }
  }
  Write-Note 'Quarantine moves complete.'
  Write-Note ("Retention policy: delete items older than {0} days manually or via scheduled task." -f $RetentionDays)
} catch {
  Write-Error $_
  exit 1
}
