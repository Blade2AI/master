#!/usr/bin/env python3
import sys
import json
from pathlib import Path

EVIDENCE_FILE = Path("Evidence/Analysis/_verified/test_invoice_stable.json")
PROPERTY_FILE = Path("Property/Scored/_drafts/test_trap_fixer.json")
LEDGER_FILE = Path("Governance/Logs/audit_chain.jsonl")


def fail(msg: str):
    print(f"? {msg}")
    sys.exit(1)


def check_evidence():
    print("?? Checking Evidence output...")
    if not EVIDENCE_FILE.exists():
        fail(f"Evidence file missing: {EVIDENCE_FILE}")

    data = json.loads(EVIDENCE_FILE.read_text(encoding="utf-8"))
    meta = data.get("_governance") or data.get("_meta") or {}

    status = meta.get("status")
    track = meta.get("track")

    if track != "stable":
        fail(f"Evidence track mismatch. Expected 'stable', got {track!r}")

    if status not in ("AUTO_VERIFIED", "VERIFIED"):
        fail(f"Evidence status mismatch. Expected AUTO_VERIFIED/VERIFIED, got {status!r}")

    print("? Evidence output passes governance checks.")


def check_property():
    print("?? Checking Property output...")
    if not PROPERTY_FILE.exists():
        fail(f"Property file missing: {PROPERTY_FILE}")

    data = json.loads(PROPERTY_FILE.read_text(encoding="utf-8"))
    condition = data.get("condition_score")
    defects = data.get("defects_detected")

    if defects and condition is not None and condition > 5:
        fail(
            f"Legislative breach: defects_detected=True but condition_score={condition} (>5)"
        )

    print("? Property output respects legislative cap (defects ? score ? 5).")


def check_ledger():
    print("?? Checking Ledger integrity...")
    if not LEDGER_FILE.exists():
        fail(f"Ledger file missing: {LEDGER_FILE}")

    lines = LEDGER_FILE.read_text(encoding="utf-8").strip().splitlines()
    if len(lines) < 1:
        fail("Ledger has no entries (expected at least GENESIS).")

    try:
        first = json.loads(lines[0])
    except json.JSONDecodeError:
        fail("Ledger first line is not valid JSON.")

    if first.get("event_type") != "GENESIS":
        fail("Ledger does not start with GENESIS event.")

    print(f"? Ledger present with {len(lines)} event(s). GENESIS confirmed.")


def main():
    print("?? SOVEREIGN INTEGRATION VERIFICATION")
    check_evidence()
    check_property()
    check_ledger()
    print("?? Integration verification: ALL CHECKS PASSED.")


if __name__ == "__main__":
    main()
