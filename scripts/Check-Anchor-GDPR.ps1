[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)][string]$AnchorPath = 'out/anchors'
)
$ErrorActionPreference='Stop'
Write-Host '== Check-Anchor-GDPR : forbidden key scan ==' -ForegroundColor Cyan

# Resolve target anchor file
if(Test-Path $AnchorPath -PathType Container){
  $latest = Get-ChildItem -Path $AnchorPath -Filter *.json -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if(-not $latest){ throw "No anchor JSON files found in directory: $AnchorPath" }
  $instancePath = $latest.FullName
} elseif(Test-Path $AnchorPath -PathType Leaf){
  $instancePath = (Resolve-Path $AnchorPath).Path
} else { throw "AnchorPath not found: $AnchorPath" }

Write-Host "Scanning: $instancePath" -ForegroundColor Cyan

# Ensure pytest installed
$python='python'
$testFile='tests/test_anchor_gdpr_guard.py'
if(-not (Test-Path $testFile)){ throw "GDPR guard test not found: $testFile" }

# Run pytest on guard test only
$proc = Start-Process -FilePath $python -ArgumentList '-m','pytest',$testFile,'-q' -PassThru -NoNewWindow -RedirectStandardOutput stdout.txt -RedirectStandardError stderr.txt
$proc.WaitForExit()

$stdout = Get-Content stdout.txt -Raw -ErrorAction SilentlyContinue
$stderr = Get-Content stderr.txt -Raw -ErrorAction SilentlyContinue
if($stdout){ Write-Host $stdout }
if($stderr){ Write-Host $stderr -ForegroundColor Yellow }
Remove-Item stdout.txt,stderr.txt -ErrorAction SilentlyContinue

if($proc.ExitCode -ne 0){ throw "GDPR guard failed (exit $($proc.ExitCode))" }
Write-Host '[OK] GDPR guard passed – no forbidden keys detected.' -ForegroundColor Green
