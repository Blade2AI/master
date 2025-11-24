# MASTER CLOSE-OUT CHECKLIST

Purpose: Provide a repeatable, auditable end-state procedure before ending a session or cutting a release.

This checklist pairs with `scripts/master_closeout.ps1` and records a human sign-off.

---

## 1) Pull + Status
- [ ] `git pull` completed
- [ ] Local branch matches expected release branch
- [ ] Uncommitted changes acceptable (or stashed/committed)

Notes:

## 2) Build / Compile (if applicable)
- [ ] Build steps completed (msbuild/other) or N/A for Python-only changes

Notes:

## 3) Unit Tests (current reality)
- [ ] Ran `python Data/boardroom_13_test.py`
- [ ] Exit code 0
- [ ] Output reviewed (warnings/errors noted)

Notes:

## 4) Adversarial Tests (placeholder)
- [ ] N/A today
- [ ] Ticket created to integrate RUN-5/RUN-6 harness

Notes:

## 5) UI/Playwright (placeholder)
- [ ] N/A today
- [ ] Ticket created to add dashboard smoke tests

Notes:

## 6) Recursive Loop Audit
- [ ] Script reported 0 potential infinite loops OR reviewed warnings and accepted risk

Notes:

## 7) Artifacts + Seal
- [ ] Log file path recorded
- [ ] Memo generated (`Data/_report/CLOSEOUT_*.md`)
- [ ] Manifest generated (`Data/_seals/closeout_*.manifest.json`)
- [ ] Seal generated (`Data/_seals/closeout_*.sha256`)

Notes:

## 8) Collab Hygiene
- [ ] Live Share ended (if active)
- [ ] Sensitive tokens/secrets scrubbed from recent changes

Notes:

## 9) Decision
- [ ] Proceed to commit/push
- [ ] Hold and remediate

Approver:
- Name:
- Date/Time:

---

How to run:
- VS Code Task (recommended): add a task to call `scripts/master_closeout.ps1`.
- Or PowerShell: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/master_closeout.ps1`
