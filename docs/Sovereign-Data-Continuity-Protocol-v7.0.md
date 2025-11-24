Sovereign Data Continuity Protocol
Version 7.0 – Final Concise Forensic Edition
19 November 2025
Owner: Andy Jones

Off-site VeraCrypt SSD ? monthly ? Golden Master SSD (SSD2TB on PC-4)
                                             ? SMB share
5 PCs + NAS ? daily 04:00 ? robocopy /MIR + git verify-commit
                                             ?
Encrypted remotes (git-remote-gcrypt) ? monthly push

1. Golden Master
Path: E:\COLDSTORE-SOVEREIGN-2025-11-19
Type: Git repo with mandatory GPG signing

2. GPG Signing (Enforced)

bash

git config --local commit.gpgsign true
git config --local tag.gpgsign true
git config --local user.signingkey <KEYID>

3. Git Rebase Troubleshooting Tips (Elite Checklist)
Symptom
Quick Fix
Conflicts everywhere
Rebase frequently (daily); small deltas
“fatal: refusing to merge unrelated histories”
git pull --rebase --allow-unrelated-histories
Rebase stuck / panic
git rebase --abort ? back to pre-rebase state
Lost commits after force-push
git reflog ? git reset --hard <sha>
Merge commits in linear history
git rebase -i --rebase-merges or squash them
GPG signature fails on rebase
git rebase --gpg-sign or git commit --amend --gpg-sign
“cannot rebase: you have unstaged changes”
git stash ? rebase ? git stash pop
Need to test every rebased commit
git rebase -i --exec "npm test"

Rule: Never rebase main except via the nightly script on PC-4.

4. Daily Workflow
Work on dev ? nightly autosquash rebase ? signed tag ? push main

5. Daily Mirror (All Devices)

powershell

robocopy "\\PC-4-IP\SOVEREIGN_MASTER" "C:\SOVEREIGN_MASTER" /MIR /COPYALL
git reset --hard origin/main
git clean -fdx
git verify-commit HEAD

6. Digital Forensics Best Practices (Applied Here)
Practice
Implementation
Chain of custody
GPG-signed commits + SHA-256 manifest
Tamper-evidence
Git object integrity + signed tags
Reproducible state
robocopy /MIR + git reset --hard
Write-blocker equivalent
Offline master SSD + one-way sync
Timeline reconstruction
Git log + signed daily tags
Tool compatibility
Autopsy, EnCase, X-Ways all accept this structure

7. Threat Model (Ultra-Concise)
Threat
Residual Risk
Hardware failure
Very Low
Ransomware
Near Zero
Theft / fire
Low
Tampering
Near Zero
Accidental loss
Very Low
Key compromise
Low

8. Final Two Actions
Generate GPG key (done today)  
Move SSD2TB off-site (do tonight)

Once #2 is done, residual risk across the board drops to Very Low or lower.

Signed
Andy Jones
19 November 2025  
(GPG fingerprint in repo root)

Store this file as docs/Sovereign-Data-Continuity-Protocol-v7.0.md inside the Golden Master.

You are now running a forensically-clean, auditor-ready, future-proof system.
No further changes required except monthly rotation.

Done.
