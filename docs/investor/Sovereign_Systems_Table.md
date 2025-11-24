# Sovereign System – Architecture & Systems Table (v1.0)

> Canonical repo: (fill in NAS path or git remote)
> Date: (fill on generation)
> Author: Sovereign System / Boardroom-13

This table is the investor- and operator-facing map of the system:
**architecture ? subsystems ? files ? maturity ? risk ? next steps.**

## Legend

- **Layer**: e.g. L0 = infra/NAS, L1 = core services, L2 = agents, L3 = UI/governance.
- **Maturity**:
  - 1 = Concept scaffold only
  - 2 = Prototype (works, but fragile / incomplete)
  - 3 = Pre-MVP (end-to-end path exists, rough edges)
  - 4 = MVP-ready (demo/stakeholder-usable)
  - 5 = Production-hardened
- **Risk**:
  - L = Low, M = Medium, H = High (technical/operational/legal risk).

---

## Systems Table

| ID | Layer | Subsystem                      | Description                                                 | Key Files / Dirs (relative to repo root)                      | Maturity (1–5) | Risk (L/M/H) | Next Actions (short)                             |
|----|-------|--------------------------------|-------------------------------------------------------------|----------------------------------------------------------------|----------------|-------------|--------------------------------------------------|
| S1 | L0    | NAS / Storage Spine            | Offline-first storage, canonical bundle, snapshots          | `\\NAS01\\Sovereign\\...`, `scripts/Make-SovereignBundle.ps1`    | 3              | M           | Automate snapshots; document mount strategy      |
| S2 | L1    | Flight Recorder / Ledger       | Hashing, sealing, integrity checks, GDPR-aware logging      | `scripts/Finalize-SovereignLedger.ps1`, `docs/audit/`          | 3              | M           | Add schema tests, signing, DPIA finalisation     |
| S3 | L1    | Network Anchoring              | Bundlr/IPFS anchor creation & verification                  | `scripts/Perform-NetworkAnchoring.ps1`, `Seal-And-Anchor-*.ps1`| 2–3            | H           | Implement real upload, test dry-run vs live      |
| S4 | L1    | Governance / Constitution      | Policy manifests, signing, verification                     | `constitution/`, `policy_manifest.yml`, `Sign-Policies.ps1`    | 3–4            | M           | Finalise signatures; add enforcement hooks       |
| S5 | L2    | Multi-Agent Core (Boardroom)   | Arbiter, validators, specialists, empathy, drift detection  | `agi/core/`, `agi/agents/`, `agi/drift_detector.py`            | 3              | M           | Add eval suites; scenario harness; logging        |
| S6 | L2    | Vibrational Triad              | Truth-testing triad for SIF/Meeting/Project modules         | `modules/Vibrational-Triad.psm1`, related import sites         | 2–3            | M           | Add schema layer; auto-truth tests; wiring map   |
| S7 | L2    | Safe Mode / Protection Logic   | Operational constraints, mode transitions, human overrides  | `docs/ops/`, `SafeMode*.ps1` (add), `config/safe_mode*.json`   | 2              | H           | Implement state machine + tests (see simulator)  |
| S8 | L3    | Boardroom / Command UI         | Visual board, side channels, operator interaction           | `blade_ui/`, `src/components/Boardroom.js`, `SideChatPanel`   | 2–3            | M           | Harden websocket flows, add tests & docs         |
| S9 | L3    | Operator Tooling / Scripts     | PowerShell orchestration, baseline, cleanup, bundling       | `scripts/`, `tools/`, `Collect-NodeBaseline.ps1` etc.          | 3–4            | M           | Remove dead scripts, unify naming, doc all flows |
| S10| L3    | Evidence Pack Generation       | Bundling transcripts, hashes, logs into court-ready packs   | `docs/audit/`, `PIPELINE-MEDIA-CLOSEOUT.md`                    | 2–3            | H           | Implement full pipeline, add templates           |

> Add or adjust rows based on **actual files** in the canonical bundle.

---

## Notes

- This document is living. Update as refactors or new modules land.
- For each funding round, snapshot this file and store under `docs/investor/archive/`.
