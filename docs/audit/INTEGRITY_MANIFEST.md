# INTEGRITY_MANIFEST

Purpose: Immutable record of Digital Dominion seal.

## Artifacts
- Clean Ledger: FINAL_LEDGER_OUTPUT/Fleet_HistoricalIP_Ledger_CLEAN.csv
- Ledger Hash Seal: FINAL_LEDGER_OUTPUT/Fleet_HistoricalIP_Ledger_CLEAN.csv.hash.txt
- Tag: v1.0-digital-dominion

## Current Seal
```
FILE=FINAL_LEDGER_OUTPUT/Fleet_HistoricalIP_Ledger_CLEAN.csv
SHA256=<REPLACE_WITH_ACTUAL_HASH>
SIZE_BYTES=<REPLACE_WITH_SIZE>
TIMESTAMP=<REPLACE_WITH_TIMESTAMP>
TAG=v1.0-digital-dominion
```
Populate values by running:
```
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\seal_ledger_hash.ps1 -FilePath .\FINAL_LEDGER_OUTPUT\Fleet_HistoricalIP_Ledger_CLEAN.csv -Force
Get-Content .\FINAL_LEDGER_OUTPUT\Fleet_HistoricalIP_Ledger_CLEAN.csv.hash.txt
```

## Verification Procedure
1. Ensure working directory is clean.
2. Compute hash:
```
sha256sum FINAL_LEDGER_OUTPUT/Fleet_HistoricalIP_Ledger_CLEAN.csv
```
(or PowerShell: `(Get-FileHash -Algorithm SHA256 -LiteralPath .\FINAL_LEDGER_OUTPUT\Fleet_HistoricalIP_Ledger_CLEAN.csv).Hash`)
3. Match result with SHA256 above.
4. Confirm tag points to commit containing this file:
```
git show v1.0-digital-dominion --name-only | find "Fleet_HistoricalIP_Ledger_CLEAN.csv"
```

## Policy
- Any modification to the ledger requires:
  - Re-run seal script.
  - Update SHA256 and TIMESTAMP here.
  - Create new annotated tag v1.<minor>-digital-dominion.
- CI must fail if hash mismatch (see workflow below).

## Branch Protection Recommendation
Protect `main` with:
- Require status check: `ledger-integrity`.
- Require signed commits (optional).
- Disallow force pushes.

## GitHub Actions (ledger-integrity.yml example)
Create `.github/workflows/ledger-integrity.yml`:
```yaml
name: ledger-integrity
on: [push, pull_request]
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Extract sealed hash
        id: seal
        run: |
          SEALED=$(grep '^SHA256=' FINAL_LEDGER_OUTPUT/Fleet_HistoricalIP_Ledger_CLEAN.csv.hash.txt | cut -d= -f2)
          echo "sealed=$SEALED" >> $GITHUB_OUTPUT
      - name: Compute current hash
        id: current
        run: |
          CUR=$(sha256sum FINAL_LEDGER_OUTPUT/Fleet_HistoricalIP_Ledger_CLEAN.csv | awk '{print $1}')
          echo "current=$CUR" >> $GITHUB_OUTPUT
      - name: Compare
        run: |
          if [ "${{ steps.seal.outputs.sealed }}" != "${{ steps.current.outputs.current }}" ]; then
            echo "Hash mismatch"; exit 1; fi
      - name: Fail if rogue entries
        run: |
          if grep -q ',False$' FINAL_LEDGER_OUTPUT/Fleet_HistoricalIP_Ledger_CLEAN.csv; then
            echo "Rogue entries detected"; exit 1; fi
```

## Future Tags
- v1.0-digital-dominion (initial seal)
- v1.1-digital-dominion (if ledger legitimately changes)

## Change Log
| Date | Action | Commit | Tag |
|------|--------|--------|-----|
| <YYYY-MM-DD> | Initial seal | <commit-sha> | v1.0-digital-dominion |

