param(
  [int]$MonteCarloN = 1000
)
$ErrorActionPreference = 'Stop'

function New-Dir($p){ if (-not [string]::IsNullOrWhiteSpace($p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }

$ws = Split-Path -Parent $PSScriptRoot
$runRoot = Join-Path $ws 'Data/test_runs'
New-Dir $runRoot
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$runDir = Join-Path $runRoot $stamp
New-Dir $runDir

$deterministic = Join-Path $ws 'agi/tests/deterministic/test_cases.py'
$monte = Join-Path $ws 'agi/tests/monte_carlo/run_redteam.py'
$fuzz = Join-Path $ws 'agi/tests/fuzz/run_dep_fuzz.py'

Write-Host "[RUN] Deterministic" -ForegroundColor Cyan
python $deterministic 2>&1 | Tee-Object -FilePath (Join-Path $runDir 'deterministic.out') | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] Deterministic tests" -ForegroundColor Red }

Write-Host "[RUN] Monte Carlo ($MonteCarloN)" -ForegroundColor Cyan
$env:MC_N = "${MonteCarloN}"
python $monte 2>&1 | Tee-Object -FilePath (Join-Path $runDir 'monte_carlo.out') | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "[WARN] Redteam script exited non-zero" -ForegroundColor Yellow }

Write-Host "[RUN] Fuzz" -ForegroundColor Cyan
python $fuzz 2>&1 | Tee-Object -FilePath (Join-Path $runDir 'fuzz.out') | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "[WARN] Fuzz script exited non-zero" -ForegroundColor Yellow }

Write-Host "[DONE] Logs -> $runDir" -ForegroundColor Green
