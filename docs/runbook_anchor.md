# Runbook: Dual Anchoring (GDPR-Safe)

## Purpose
Produce immutable, GDPR-minimised anchors for ledger/heartbeat state using Arweave (Bundlr) + IPFS (nft.storage). No personal data leaves controlled storage.

## Prerequisites
- Bundlr wallet funded (MATIC / Polygon) – env var BUNDLR_KEY loaded (do NOT commit)
- nft.storage API key – env var NFT_STORAGE_API_KEY loaded (do NOT commit)
- Node identifier set: SOVEREIGN_NODE_ID
- Optional signing key id: SOVEREIGN_SIGNING_KEY_ID
- Ledger file present (default path referenced when task runs)

## Files
- schemas/event_anchor.json (strict GDPR-safe schema)
- scripts/Seal-And-Anchor-Dual.ps1 (stub: compute root, build anchor JSON, future network wiring)
- scripts/Verify-FullChain.ps1 (walk chain from genesis until zero-root)
- scripts/Invoke-NodeErasure.ps1 (simulate GDPR erasure via zero-root anchor)

## Steps (Initial Stub Phase)
1. Update env vars (PowerShell):
   $env:SOVEREIGN_NODE_ID = 'node-archival-01'
   $env:SOVEREIGN_SIGNING_KEY_ID = 'key-ed25519-01'
   (Load BUNDLR_KEY & NFT_STORAGE_API_KEY via secure method.)
2. Run anchor stub task (VS Code task: Anchor: Seal Dual (Stub)).
3. Inspect out/anchors/event_anchor_<GUID>.json ? confirm fields populated, tx_id / cid still null.
4. (Future) Implement network upload wiring – populate backends.arweave.tx_id and backends.ipfs.cid.
5. (Future) Sign anchor JSON – set signature.value.
6. Emit event_anchor via recorder once network receipts & signature complete.

## Verification
- Schema validation (to be added): validate anchor JSON against schemas/event_anchor.json.
- Chain verification: after first real uploads, run scripts/Verify-FullChain.ps1 with genesis TXID/CID.

## Erasure Procedure (Simulation)
1. Ensure permanent_anchor.json exists with latest tx_id / cid.
2. Run: scripts/Invoke-NodeErasure.ps1 -NodeId node-archival-01
3. Publish zero-root anchor (network wiring required). Verify termination in chain walk.

## Operational Notes
- DO NOT embed names, emails, IPs, message content, or free text into the anchor schema.
- Only hashes and technical metadata are immutable.
- Personal-data erasure applies to mutable ledger; anchors remain as non-personal mathematical attestations.

## Next Implementation Targets
- Network upload (Bundlr + nft.storage) with robust retry.
- jsonschema validation hook (Python or Node).
- Anchor event emission: recorder.log_event('anchor', anchor_reduced_payload).
- Signature generation + verification script.
- CI tests: schema validation, GDPR sanitization, Merkle determinism.

## Acceptance Criteria (P0)
- Anchor JSON contains only allowed fields.
- No null safety for mandatory fields (except tx_id / cid pre-upload).
- Root hash stable and reproducible.
- Schema validation integrated in CI.
