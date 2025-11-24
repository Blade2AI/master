# Fleet Audit Suite v1.0-digital-dominion – Integration Plan

## Overview
This plan integrates sealed scanners and the finalization script into this repository following the v1.0-digital-dominion tag convention.

## Files to Add
- scripts/deep_forge_scanner_SEALED.ps1
- scripts/ai_models_scanner_SEALED.ps1
- scripts/run_fleet_scan_SEALED.ps1
- finalize_and_seal.sh (repo root)
- docs/audit/QUICK_REFERENCE.md
- docs/audit/FINALIZATION_WORKFLOW.md
- docs/audit/FLEET_SCAN_USAGE.md

## Steps
1. Create folders
```
mkdir -p scripts docs/audit
```
2. Copy files into place.
3. Make finalizer executable and run from Git Bash
```
chmod +x ./finalize_and_seal.sh
./finalize_and_seal.sh
```
4. Verify
```
git tag -l | findstr dominion
git show v1.0-digital-dominion --name
```
5. CI/Protection
- Ensure ledger-integrity and continuous-assurance workflows are passing.
- Enable branch protection requiring both checks.

## Post-Integration
- Copy scanners to PC4 (e.g., C:\SCANNERS) and verify hashes vs manifest.
- Execute fleet scans; consolidate; finalize ledger; seal and tag as per governance procedures.
