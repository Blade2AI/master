import json
import hashlib
import os
from pathlib import Path
from src.core.router import SovereignRouter

LOG_PATH = Path("Governance/Logs/audit_chain.jsonl")


def generate_test_traffic():
    print("\u26A1 Generating test traffic...")
    
    # Ensure GENESIS
    if not LOG_PATH.exists() or LOG_PATH.stat().st_size == 0:
        router = SovereignRouter("boardroom")
        router.log_event("GENESIS", {"message": "Sovereign System Ignited"})
        print("   GENESIS event logged.")

    router = SovereignRouter("evidence")
    for i in range(1, 4):
        router.process(
            filename=f"smoke_test_{i}.json",
            data={"test_run": i},
            confidence=0.9 + (i / 100),
            estimated_cost=0.01,
        )
    print("   3 Events logged.")


def verify_chain_integrity():
    print("\n\U0001F50D Auditing Ledger Integrity...")
    if not LOG_PATH.exists():
        print("\u274C No log found!")
        return
    with open(LOG_PATH, "r") as f:
        lines = f.readlines()
    previous_hash = "0" * 64
    errors = 0
    for index, line in enumerate(lines):
        entry = json.loads(line)
        stored_hash = entry.pop("hash")
        if entry["prev_hash"] != previous_hash:
            print(f"   \U0001F6A8 BROKEN CHAIN at Line {index + 1}")
            print(f"      Expected Prev: {previous_hash[:16]}...")
            print(f"      Found Prev:    {entry['prev_hash'][:16]}...")
            errors += 1
        payload_str = json.dumps(entry, sort_keys=True)
        calculated_hash = hashlib.sha256(payload_str.encode()).hexdigest()
        if calculated_hash != stored_hash:
            print(f"   \U0001F6A8 TAMPER DETECTED at Line {index + 1}")
            print(f"      Calculated: {calculated_hash[:16]}...")
            print(f"      Stored:     {stored_hash[:16]}...")
            errors += 1
        previous_hash = stored_hash
    if errors == 0:
        print(f"\u2705 AUDIT PASSED. {len(lines)} entries verified. Chain is unbroken.")
    else:
        print(f"\u274C AUDIT FAILED. {errors} integrity violations found.")


if __name__ == "__main__":
    os.environ["TRACK"] = "insider"
    try:
        generate_test_traffic()
    except Exception as e:
        print(f"Setup failed: {e}")
        print("Did you add 'evidence' to AGENT_CONFIG in router.py?")
        exit(1)
    verify_chain_integrity()
