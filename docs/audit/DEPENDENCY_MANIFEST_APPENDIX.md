# Dependency Manifest — Governance Appendix

Purpose
- Define the manifest as the canonical dependency evidence for auditing, CI, and runtime preflight.
- Provide schema, verification commands, CI wiring, and an audit checklist auditors can follow.

Scope
- C# projects (`.csproj`) and their package references
- Python environments (`requirements*.txt`) and hashes
- Node projects (`package.json`) and lockfiles
- Lockfiles (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `poetry.lock`, `Pipfile.lock`) and their SHA?256
- Signed artefacts and CI artifacts retention

Canonical files (examples)
- `dependency_manifest.json` (root manifest)
- `dependency_manifest.signature.json` (internal signature metadata / hash)
- `dependency_manifest.json.asc` (GPG detached armored signature)

Manifest (high?level) schema
- `generated_utc` (string, ISO?8601 UTC)
- `root` (string, absolute path or repo root identifier)
- `projects` (array)
  - `name` (string)
  - `path` (string, repo relative)
  - `target_framework` (string)
  - `package_references` (array of { `id`, `version` })
- `python_envs` (array)
  - `path` (string)
  - `packages` (array of strings)
  - `hash_sha256` (string)
- `node_envs` (array)
  - `path`, `name`, `version`, `dependencies`, `devDependencies`, `hash_sha256`
- `lockfiles` (array)
  - `path`, `full_path`, `type`, `hash_sha256`

Minimal example (abridged)

```json
{
  "generated_utc": "2025-11-22T12:34:56Z",
  "root": "C:\\Users\\andyj\\source\\repos\\PrecisePointway\\master",
  "projects": [
    {
      "name": "PrecisePointway.Web",
      "path": "src/PrecisePointway.Web/PrecisePointway.Web.csproj",
      "target_framework": "net8.0",
      "package_references": [{"id":"Serilog.AspNetCore","version":"8.0.0"}]
    }
  ],
  "python_envs": [{"path":"AI_Agent_Research/requirements.txt","hash_sha256":"..."}],
  "node_envs": [{"path":"blade_ui/package.json","name":"blade_ui","hash_sha256":"..."}],
  "lockfiles": [{"path":"blade_ui/package-lock.json","type":"npm","hash_sha256":"..."}]
}
```

Local verification (developer machine)
- Generate manifest:
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Generate-DependencyManifest.ps1 -Root "${PWD}" -Output dependency_manifest.json`
- Compute sha256 (Windows PowerShell):
  - `Get-FileHash -Algorithm SHA256 .\dependency_manifest.json | Format-List`
- Hash verification (Linux/macOS):
  - `sha256sum dependency_manifest.json`
- Sign (local, optional KMS/GPG):
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Sign-DependencyManifest.ps1 -ManifestPath dependency_manifest.json -OutJson dependency_manifest.signature.json`
- GPG verify (auditor):
  - `gpg --import publickey.asc` (once)
  - `gpg --verify dependency_manifest.json.asc dependency_manifest.json`
- Check checksum:
  - `sha256sum -c DependencyManifest.sha256` (if manifest checksum file exists)

CI wiring (GitHub Actions)
- Workflow trigger: on changes to `**/*.csproj`, `**/requirements*.txt`, `**/package.json`, lockfiles, or manifest scripts.
- Steps (summary):
  1. Checkout
  2. Run `scripts/Enumerate-Csproj.ps1`
  3. Run `scripts/Generate-DependencyManifest.ps1` ? produce `dependency_manifest.json`
  4. Run `scripts/Sign-DependencyManifest.ps1` ? produce `dependency_manifest.signature.json`
  5. Import GPG key (action) and produce detached signature `dependency_manifest.json.asc`
  6. Upload artefacts (`dependency_manifest.json`, `.signature.json`, `.json.asc`) to CI storage

Secrets required for GPG signing (store in repo Settings ? Secrets)
- `GPG_PRIVATE_KEY` — ASCII armored private key
- `GPG_PASSPHRASE` — passphrase (optional; recommended)

CI snippet (concept)

```yaml
- uses: crazy-max/ghaction-import-gpg@v6
  with:
    gpg_private_key: ${{ secrets.GPG_PRIVATE_KEY }}
    passphrase: ${{ secrets.GPG_PASSPHRASE }}

- name: GPG sign manifest
  run: |
    gpg --batch --yes --detach-sign --armor dependency_manifest.json
```

VS Code integration (developer preflight)
- Tasks added:
  - `Preflight: Dependency Lockfiles` ? runs `scripts/Preflight-DependencyLockfiles.ps1`
  - `Sovereign: Dependency Manifest Generate` ? runs manifest generation
- Configure `preLaunchTask` in `.vscode/launch.json` for each run configuration:
  - `"preLaunchTask": "Preflight: Dependency Lockfiles"`
  - Optionally chain to `Sovereign: Preflight Validate Dependencies`
- Behavior: preflight failure prevents launch and surfaces clear remediation steps.

Audit checklist (recommended, for auditors)
1. Confirm CI run for commit: check `dependency-manifest` artefact exists in workflow run.
2. Download `dependency_manifest.json`, `dependency_manifest.signature.json`, `dependency_manifest.json.asc`.
3. Verify GPG signature:
   - `gpg --import publickey.asc`
   - `gpg --verify dependency_manifest.json.asc dependency_manifest.json`
4. Verify internal hash metadata matches actual file hash:
   - Read `dependency_manifest.signature.json`, compare `hash` field vs `sha256` of `dependency_manifest.json`.
5. Verify lockfiles listed in `lockfiles` exist and their `hash_sha256` values match computed SHA?256.
6. Verify projects list against repository `.sln` and `.csproj` files. Spot-check package versions.
7. Confirm retention: artefacts retained in CI for required period (policy).
8. Confirm key rotation policy and presence of public key + fingerprint in governance docs.

Governance notes
- Key rotation: recommend annual rotation or immediately following a key compromise. Publish new public key and record revocation info.
- Retention: store manifest + signatures with CI artefacts and in archival storage for regulatory timeframes.
- Incident response: if manifest mismatch discovered, halt release and initiate drift investigation using `scripts/Run-RepoRealityCheck.ps1` and `agi/core/drift_detector.py`.

Minimal operational SOP (1?page)
- Developer: run `Sovereign: Preflight Validate Dependencies` in VS Code before debug.
- CI: runs `dependency-manifest` workflow on push; must pass before merge to `main`.
- Auditor: run audit checklist above and record verification steps in audit log.

Appendix links (repo)
- `scripts/Generate-DependencyManifest.ps1`
- `scripts/Sign-DependencyManifest.ps1`
- `.github/workflows/dependency-manifest.yml`
- `scripts/Preflight-DependencyLockfiles.ps1`
- `docs/dependency_validation_flow.md`

Contact
- For operational questions, open an issue referencing `DEPENDENCY_MANIFEST_APPENDIX`.

---

Generated by automation. Amend as required for local governance needs.