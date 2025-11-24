param(
    [switch]$VerboseOutput
)

Write-Host "=== SOVEREIGN REPO REALITY CHECK ===" -ForegroundColor Cyan
Write-Host "Repo root: $(Get-Location)" -ForegroundColor DarkCyan

function Test-Item {
    param(
        [string]$Path,
        [string]$Label
    )
    if (Test-Path $Path) {
        Write-Host "[FOUND] $Label -> $Path" -ForegroundColor Green
    } else {
        Write-Host "[MISSING] $Label -> $Path" -ForegroundColor Red
    }
}

Write-Host "`n-- Implemented / Real: Files & Directories --`n" -ForegroundColor Yellow
Test-Item "agi\core" "Agent core directory (arbiter/validator/specialist/etc.)"
Test-Item "constitution\policy_manifest.yml" "Policy manifest"
Test-Item "Sign-Policies.ps1" "Sign-Policies script"
Test-Item "Validate-Policy.ps1" "Validate-Policy script"
Test-Item "agi\core\policy_signature.py" "Policy signature helper"
Test-Item "Finalize-SovereignLedger.ps1" "Ledger finalize script"
Test-Item "seal_ledger_hash.ps1" "Ledger hash sealing script"
Test-Item "docs\audit\INTEGRITY_MANIFEST.md" "Integrity manifest doc"
Test-Item "finalize_and_seal.sh" "Finalize & seal shell script"
Test-Item ".github\workflows" "GitHub workflows directory"
Test-Item "master_closeout.ps1" "Master close-out script"
Test-Item "scripts\run_all.ps1" "Run-all pipeline"
Test-Item "docs\PIPELINE-MEDIA-CLOSEOUT.md" "Media close-out doc"
Test-Item ".vscode\tasks.json" "VS Code tasks config"
Test-Item "Makefile" "Makefile (discovery/health/audit)"
Test-Item "scripts\Transcribe-Video.ps1" "Transcribe-Video script"
Test-Item "scripts\G-Transcript.ps1" "G-Transcript script"
Test-Item "agi\tests" "AGI test suite directory"
Test-Item "scripts\Run-Empathy-Tests.ps1" "Run-Empathy-Tests script"
Test-Item "scripts\Invoke-RemoteEmpathyTests.ps1" "Invoke-RemoteEmpathyTests script"
Test-Item "EliteTruthEngine\server.py" "Truth engine (FastAPI server)"
Test-Item "EliteTruthEngine\build_index.py" "Truth engine index builder"
Test-Item "EliteTruthEngine\requirements.txt" "Truth engine requirements"
Test-Item "SOVEREIGN_MODEL_POLICY.md" "Sovereign model policy"
Test-Item "constitution\trauma_informed_standard.md" "Trauma-informed standard"
Test-Item "Generate-GoldenMaster-Manifest.ps1" "Golden master manifest generator"
Test-Item "scripts\FleetBootstrap.ps1" "Fleet bootstrap script"
Test-Item "scripts\Review-VSCode-Fleet.ps1" "VS Code fleet review script"
Test-Item "scripts\Bootstrap-All.ps1" "Bootstrap all script"
Test-Item "scripts\Healthcheck.ps1" "Healthcheck script"
Test-Item "scripts\Ledger-Audit.ps1" "Ledger audit script"
Test-Item ".git\hooks\pre-commit" "Git pre-commit hook"

Write-Host "`n-- Conceptual / Missing Runtime Artifacts (quick probes) --`n" -ForegroundColor Yellow
Test-Item "Queue-Command.ps1" "Remote fleet command queue script (expected MISSING)"
Test-Item "Start-BehavioralOS-Host.ps1" "Behavioral OS host script (expected MISSING)"
Test-Item "agi\core\model_stack.yaml" "Model stack config (exists, but no runner yet)"
Test-Item "deploy" "Deployment manifests directory (Docker/K8s/systemd)"
Test-Item "payments" "Payment/economic rails directory"
Test-Item "archive" "Immutable archival / Arweave adapter directory"
Test-Item "blade_ui" "UI directory"

Write-Host "`n=== Reality Check Completed ===" -ForegroundColor Cyan
if ($VerboseOutput) {
    Write-Host "`nNOTE:" -ForegroundColor DarkYellow
    Write-Host "Green = file/folder exists."
    Write-Host "Red   = missing as of this run (may still be planned or implemented elsewhere)."
}
