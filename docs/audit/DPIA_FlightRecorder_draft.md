# Data Protection Impact Assessment (DPIA) – Flight Recorder (Proof Mode)

> Draft for review – Node-0 (UK) Sovereign System

---
## 1. Overview of Processing
The **Flight Recorder** produces a GDPR-safe, cryptographically verifiable trace of key system events. It anchors only technical hashes and receipts (not event content) to immutable storage (Arweave/IPFS). Ledger content remains in mutable, access-controlled storage subject to retention policy.

---
## 2. Nature, Scope, Context, Purpose
**Nature**: Hashing ledger snapshots; emitting anchor JSON (root_hash, hash_algorithm, node_id, timestamp_utc, backend receipts, optional signature). No personal data in anchor payloads.
**Scope**: Node-0 (UK) proof environment; future multi-node expansion.
**Context**: High-integrity, neurodivergent/trauma-aware operational environment requiring strong safeguards against accidental disclosure.
**Purpose**: Verifiable integrity (tamper-evident), forensic readiness, investor/regulator assurance.

---
## 3. Legal Basis
- Legitimate interests (Art. 6(1)(f) GDPR): system integrity, fraud prevention, assurance.
- Future production: compliance with security/audit obligations.
Anchors are minimised to avoid personal-data classification.

---
## 4. Data Categories & Flows
**Ledger (mutable)**: May contain user/system event metadata, paths, internal IDs.
**Anchor (immutable)**: ONLY technical: root_hash, hash_algorithm, node_id (pseudonymous), timestamp_utc, backends receipts (tx_id/cid), optional signature metadata.
**Flow**:
1. Ledger snapshot created locally.
2. root_hash computed.
3. Anchor JSON built and validated.
4. Anchor JSON transmitted to Bundlr (Arweave) and nft.storage (IPFS) – future production.
5. Receipts stored locally.

---
## 5. Risks
1. Accidental personal data inclusion in anchor JSON.
2. Linkability via node_id + precise timestamps.
3. Misconfiguration sending full ledger off-node.
4. Key/secret leakage in repo or logs.

---
## 6. Mitigations
1. Strict JSON schema (`schemas/event_anchor.json`) + `additionalProperties:false`.
2. Tests & CI guard (GDPR sanitisation) fail on PII-like keys.
3. Anchor script only references ledger hash; explicit GDPR warnings.
4. Env-based secrets; example file (`config/flight_recorder.env.example`) forbids committed secrets.
5. Pseudonymous node IDs (e.g. node-uk-01) – no user/tenant encoding.
6. Runbook & operator checklist define human verification steps.

---
## 7. Residual Risk & Next Steps
Residual risk (proof mode): Low if schema/tests remain intact. Main exposure: developer misconfiguration.
**Next**:
- Implement real network anchoring with transmission tests.
- Harden scheduled task principal (service account).
- Independent code/privacy review & penetration test for data leakage paths.

---
## 8. Sign-off (Draft)
System Owner (Data Controller Rep): _Name / Signature / Date_
DPO / Privacy Lead: _Name / Signature / Date_
Security Lead: _Name / Signature / Date_
