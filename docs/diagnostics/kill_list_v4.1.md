# FLIGHT RECORDER – FINAL KILL LIST v4.1
**November 21, 2025 – 8-WEEK DEATH MARCH EDITION**  
**Hard Deadline: January 17, 2026**  
**Rule:** If it’s not merged to `main`, CI-green, running on real hardware, and GDPR-lawyer-signed by January 17 ? the recorder is **frozen to “R&D only” and removed from all investor decks and sales promises** until it passes every gate.

## P0 – DO OR DIE (Must be 100% complete by December 20, 2025 – 4 weeks, no mercy)
- [ ] REC-01 `src/recorder/core.py` + `config/recorder_config.yaml`  
      ? append-only JSONL, enforces schema, node_id, timestamp, event_id (UUID v7)  
      DoD: `python -m recorder.core --smoke-test` produces 10 valid lines, file survives forced crash
- [ ] REC-02 ALL heartbeats & manifests go through recorder ONLY  
      ? Delete every direct File-Write in old scripts. One-line call: `Log-Event heartbeat $payload`  
      DoD: grep the entire repo ? zero `Out-File.*\.jsonl` outside `recorder/`
- [ ] ANC-01 GDPR-ZERO ANCHOR PAYLOAD – LAWYER-SIGNED v1 FOREVER  
      Exact 5 lines, <200 bytes, nothing else ever:
```
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  ? 128-hex dual-hash root
2025-12-20T23:59:59Z
node-archival-01
sovereign-fr-v4.0
0000000000000000000000000000000000000000000000000000000000000000  ? previous TXID or 64×0
```
      DoD: `docs/legal/anchor_payload_gdpr_certificate.pdf` signed by EU-qualified counsel + merged
- [ ] ANC-02 `scripts/Seal-And-Anchor.ps1` v5 – the one we go to court with  
      ? builds payload above ? Bundlr mainnet upload ? 3× retry ? writes `event_anchor` via recorder  
      DoD: 1000 consecutive mainnet anchors in 7-day burn test, total cost ? $11, zero personal data
- [ ] ANC-03 Payload sanitization gate – CI kills any leak  
      ? `tests/test_anchor_gdpr_compliance.py` scans every anchor event for forbidden keys  
      DoD: PR that adds `user_email` (or similar) anywhere in anchor payload fails CI instantly
- [ ] SCH-01 Schema wall + CI execution  
      ? jsonschema validation for every event type ? runs on every push ? red = blocked merge  
      DoD: CI red on `main` if any event violates schema
- [ ] MRK-01 Dual-hash Merkle determinism lock  
      ? golden dataset of 100 files ? single known 128-hex root forever  
      DoD: test fails if root ever changes (even by 1 bit)
- [ ] AUT-01 `Register-ScheduledTasks.ps1` – nuclear version  
      ? installs `Sovereign_Heartbeat` (15 min) + `Sovereign_Anchor` (55 min) as SYSTEM, restart=5  
      DoD: Screenshot of Task Scheduler history with ?500 successful runs, no manual touches
- [ ] DOC-01 Runbook that a stranger can execute blindfolded  
      ? `docs/runbook.md` ? bare Windows 11 ? first anchor in ?30 minutes  
      DoD: Video proof by non-dev team member
- [ ] DOC-02 Full GDPR DPIA + Article 35 documentation  
      ? `docs/legal/FlightRecorder_DPIA_v1.0.pdf` + counsel sign-off  
      DoD: Ready for DPA-style inspection tomorrow

### P0 Acceptance Gate – ALL must be true by Dec 20 or recorder is “R&D only”
1. 2000+ mainnet Arweave anchors automatically published
2. Total anchoring cost ? $25
3. EU lawyer has signed: “No personal data in anchors; erasure handled off-chain in line with EDPB guidance”
4. Chain verifiable with ONLY genesis TXID from a fresh VM
5. CI 100% green for 14 consecutive days
6. Runbook executed successfully by external contractor

If any of these are missed by Dec 20 ? recorder is **not allowed in investor deck or sales promises** until fixed.

---
## P1 – REGULATOR TEARS (January 3, 2026)
- [ ] SIG-01 Evidence pack GPG signing + verification scripts  
- [ ] EVP-01 Evidence pack nightly auto-upload to Arweave (whole zip = one TXID)  
- [ ] ERA-01 `Invoke-NodeErasure.ps1` – Art.17 kill switch (zero-root anchor + key shredding)  
- [ ] FLEET-01 Fleet indexer + `fleet_status.json` (health, last anchor age)

## P2 – POLISH (January 17, 2026)
- [ ] OBS-01 Blade UI live dashboard (reads `fleet_status.json`)  
- [ ] Triple redundancy (Arweave + IPFS + Filecoin)

---
## FINAL TEST CEREMONY – January 17, 2026
72-hour zero-touch burn test on real fleet:
- ? 5000 heartbeats logged
- ? 3000 mainnet anchors
- Evidence pack generated nightly, signed, anchored
- External verifier (lawyer + investor) runs `Verify-FullChain.ps1` + `Verify-EvidencePack.ps1` ? green
- Erasure simulation ? zero-root anchor + key-handling process executed in <4 hours

**If any single item above fails:**
- Recorder stays **flagged as “experimental / R&D only”**
- It is **excluded from live product claims and investor materials** until all criteria pass in a repeat test window.

No extensions.  
No “close enough”.  
No mercy on quality – just no more self-destruct button.

Open the issues.  
Label `kill-list` `gdpr` `blocker`.  
Assign and execute.
