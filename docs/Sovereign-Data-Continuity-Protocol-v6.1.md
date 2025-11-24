# Sovereign Data Continuity Protocol v6.1

Date: 19 November 2025

Owner and Custodian: Andy Jones

Header (for PDF): Sovereign Data Continuity Protocol v6.1

Footer (for PDF): Andy Jones – Confidential – 19 November 2025

Table of Contents
- Introduction
- Golden Master Repository
- GPG Signing
- Git Branching and Rebase Strategies
- Encrypted Git Remotes
- VeraCrypt Off-Site SSD
- Daily Mirror Synchronization
- Threat Model
- Disaster Recovery Procedure
- Mandatory Completion Actions
- Status
- Amendment History
- Custodian Approval

---

## 1. Introduction
This protocol defines the architecture, processes, and controls for maintaining a single, verifiable master repository of all critical assets, including source code, legal evidence, and personal records.

Assurances:
- Integrity and tamper-evidence through cryptographic signing.
- Automated synchronization across five Windows PCs and one TerraMaster NAS.
- Resilience to hardware failure, malicious actions, and environmental risks.
- Compliance with forensic and audit standards.

All changes are tracked in Git with GPG signing. No manual intervention is required post-setup.

## 2. Golden Master Repository
- Device: 2 TB external SSD (labeled "SSD2TB").
- Primary Host: PC-4 (static IP: [insert IP]).
- Canonical Root: `E:\COLDSTORE-SOVEREIGN-2025-11-19`.

Directory Structure:

```
COLDSTORE-SOVEREIGN-2025-11-19/
??? .git/                          # Git repository with GPG signing
??? PROJECTS_ACTIVE/
??? PROJECTS_ARCHIVE/
??? LEGAL_AUDIT/
??? PERSONAL_SENSITIVE/
??? HASH_MANIFESTS/
    ??? MASTER_MANIFEST_yyyy-MM-dd.sha256
```

The entire root is initialized as a Git repository.

## 3. GPG Signing
Setup (execute on PC-4; air-gapped recommended):

```bash
gpg --full-generate-key          # Ed25519 or RSA 4096
git config --local user.signingkey <KEYID>
git config --local commit.gpgsign true
git config --local tag.gpgsign true
git config --local pull.rebase true
git config --local rebase.autosquash true
```

Verification:

```bash
git verify-commit <sha>   # commits
git tag -v <tag>          # tags
```

All operations require valid signatures; unsigned changes are rejected.

## 4. Git Branching and Rebase Strategies
Rebase-only workflow for linear, auditable history.

Branches:
- `main`: Immutable master; rebase promotion only (PC-4).
- `dev`: Daily work; autosquash fixups.
- `legal-hold/*`: Evidential bundles; never rebased (signed tags).

Rebase Strategies (summary):
- Standard Refresh: `git rebase origin/main` – Replays changes on new base.
- Interactive Cleanup: `git rebase -i origin/main` – Squash/reorder commits.
- Autosquash Fixups: `git commit --fixup=<sha>` then `git rebase -i --autosquash`.
- Onto Rebase: `git rebase --onto main <old-base> dev` – Move branch base.
- Preserve Merges: `git rebase --rebase-merges origin/main` (rare).
- Abort/Recover: `git rebase --abort`; `git reflog` + `git reset --hard <ref>`.
- Avoid Rewrites: Never rebase shared history unless force-push agreed.

Daily Workflow (any device):

```bash
git pull --rebase origin main
git commit -S --fixup=HEAD~1
git push origin dev
```

Nightly Promotion (PC-4, 03:55 AM):

```bash
git fetch origin dev
git checkout main
git rebase --autosquash --gpg-sign dev
git push --force-with-lease origin main
git tag -s "snapshot/$(date +%F)" -m "Daily snapshot"
git push --tags
```

## 5. Encrypted Git Remotes (git-remote-gcrypt)
Setup:

```bash
pip install git-remote-gcrypt
git remote add nas-crypt gcrypt::/volume1/Encrypted/Sovereign.git
git remote add offsite-crypt gcrypt::file:///F/Sovereign-Encrypted.git
```

Push (monthly, PC-4):

```bash
git push nas-crypt main --tags --force
git push offsite-crypt main --tags --force
```

## 6. VeraCrypt Off-Site SSD
- Whole-disk encryption (AES + SHA-512).
- Keyfile (256-byte random) on separate USB.
- Backup header exported.
- Quarterly: Mount read-only, `git fsck`, rehash manifest.
- Store off-site; mount only for rotation.

## 7. Daily Mirror Synchronization (04:00 AM)

```bash
robocopy "\\<PC-4-IP>\SOVEREIGN_MASTER" "C:\SOVEREIGN_MASTER" /MIR /COPYALL /MT:64
cd "C:\SOVEREIGN_MASTER"
git reset --hard origin/main
git clean -fdx
git verify-commit HEAD || exit 1
```

## 8. Threat Model

| Threat            | Mitigation                                 | Residual Risk |
|-------------------|---------------------------------------------|---------------|
| Hardware failure  | Multi-mirror + off-site rotation            | Very Low      |
| Ransomware        | Offline master + one-way sync + GPG verify  | Near Zero     |
| Theft/fire        | Off-site VeraCrypt + gcrypt remote          | Low           |
| Tampering         | GPG-signed history + SHA-256 manifest       | Near Zero     |
| Accidental damage | Rebase-only + nightly mirror                | Very Low      |
| Key compromise    | Revocation cert + subkey rotation           | Low           |
| Bit rot           | `git fsck` + quarterly rehash               | Very Low      |
| Insider deletion  | Immutable main + legal-hold tags            | Very Low      |
| Network attacks   | Encrypted SMB + git-remote-gcrypt           | Very Low      |

## 9. Disaster Recovery
- Attach master SSD.
- `robocopy E:\... C:\SOVEREIGN_MASTER /MIR`.
- `git verify-commit HEAD`.
- Time: < 15 minutes.

## 10. Mandatory Completion Actions
- Generate GPG key on PC-4.
- Remove master SSD from premises.

## 11. Status – 19 November 2025

| Component           | Status    | Due       |
|---------------------|-----------|-----------|
| Master SSD + manifest | Complete | —         |
| GPG signing         | Complete  | —         |
| git-remote-gcrypt   | Complete  | —         |
| Daily sync          | Complete  | —         |
| Off-site rotation   | Pending   | Immediate |

## 12. Amendment History
- v6.1: Refined for defensibility and clarity.

## 13. Custodian Approval
I, Andy Jones, approve this protocol as the governing standard.

Signature: ___________________________

Date: 19 November 2025

(GPG fingerprint: [insert])

---

PDF Instructions
- Use Word or Google Docs to add page numbers, headers, and a cover page with title.
- Export to PDF with embedded fonts.
- Optionally, digitally sign the PDF with your GPG key.
