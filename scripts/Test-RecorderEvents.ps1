<#!
.SYNOPSIS
  Batch-validate recorder event JSON files against schemas.
.DESCRIPTION
  Scans an events directory recursively for *.json files. For each file:
    - Reads its JSON
    - Ensures an event_type exists
    - Invokes Python validator (agi/core/validate_event.py) which maps event_type ? schema
  Aborts (non?zero exit code) if any file fails validation.
.PARAMETER EventsRoot
  Root directory containing event JSON files (recursive).
.PARAMETER PythonExe
  Python executable to use (default 'python').
.PARAMETER FailFast
  If set, stops on first failure instead of continuing.
#>
[CmdletBinding()]param(
  [string]$EventsRoot = 'data/recorder/events',
  [string]$PythonExe = 'python',
  [switch]$FailFast
)
$ErrorActionPreference='Stop'
Write-Host '== Test-RecorderEvents : batch validation ==' -ForegroundColor Cyan
Write-Host "Events root : $EventsRoot"
Write-Host "Python exe  : $PythonExe"

if(-not (Test-Path $EventsRoot)){
  Write-Host "[INFO] Events root not found – nothing to validate." -ForegroundColor Yellow
  exit 0
}

$files = Get-ChildItem -Path $EventsRoot -Filter '*.json' -Recurse -ErrorAction Stop
if(-not $files){
  Write-Host '[INFO] No event JSON files found.' -ForegroundColor Yellow
  exit 0
}

$fail = @()
$pass = 0
foreach($f in $files){
  Write-Host "Validating: $($f.FullName)" -NoNewline
  # Quick sanity parse to confirm event_type exists
  try {
    $raw = Get-Content -LiteralPath $f.FullName -Raw
    $evt = $raw | ConvertFrom-Json -ErrorAction Stop
    if(-not $evt.event_type){ throw "Missing event_type" }
  } catch {
    Write-Host ' FAIL (parse)' -ForegroundColor Red
    $fail += $f.FullName
    if($FailFast){ break }
    continue
  }
  & $PythonExe agi/core/validate_event.py --file $f.FullName 2>$null
  if($LASTEXITCODE -eq 0){
    Write-Host ' OK' -ForegroundColor Green
    $pass++
  } else {
    Write-Host ' FAIL (schema)' -ForegroundColor Red
    $fail += $f.FullName
    if($FailFast){ break }
  }
}

Write-Host ''
Write-Host 'Summary:' -ForegroundColor Cyan
Write-Host "  Passed : $pass"
Write-Host "  Failed : $($fail.Count)"
if($fail.Count -gt 0){
  Write-Host ''
  Write-Host 'Failed files:' -ForegroundColor Red
  $fail | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
  Write-Host ''
  Write-Host 'Result: RECORDER EVENTS INVALID.' -ForegroundColor Red
  exit 1
}
Write-Host 'Result: ALL RECORDER EVENTS VALID.' -ForegroundColor Green
exit 0
