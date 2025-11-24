import os
import json
import shutil
import time
from pathlib import Path

DRAFTS = Path("Evidence/Analysis/_drafts")
VERIFIED = Path("Evidence/Analysis/_verified")
AUDIT = Path("Governance/Logs/audit-insider.jsonl")

def ensure_dirs():
    VERIFIED.mkdir(parents=True, exist_ok=True)
    AUDIT.parent.mkdir(parents=True, exist_ok=True)

def log_action(filename: str, decision: str):
    entry = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "filename": filename,
        "decision": decision,
        "human_reviewer": "CLI",
        "source": "review_console"
    }
    with AUDIT.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry) + "\n")

def review():
    ensure_dirs()
    files = [f for f in DRAFTS.iterdir() if f.suffix == '.json']
    if not files:
        print("? No pending drafts.")
        return
    print(f"?? Found {len(files)} drafts pending review.\n")
    for fp in files:
        with fp.open(encoding="utf-8") as json_file:
            try:
                data = json.load(json_file)
            except json.JSONDecodeError:
                print(f"??  Skipping corrupt JSON: {fp.name}")
                continue
        gov = data.get('_governance', {})
        print(f"--- DOC: {fp.name} ---")
        print(f"Claims: {data.get('claims') or data.get('claim')}")
        print(f"Flags:  {data.get('flags')}")
        print(f"Conf:   {gov.get('confidence')} (threshold {gov.get('threshold')})")
        choice = input("[A]pprove / [R]eject / [S]kip ? ").strip().lower()
        if choice == 'a':
            shutil.move(str(fp), VERIFIED / fp.name)
            log_action(fp.name, "APPROVE")
            print("? Promoted.")
        elif choice == 'r':
            fp.unlink(missing_ok=True)
            log_action(fp.name, "REJECT")
            print("? Rejected (Deleted).")
        else:
            print("? Skipped.")

if __name__ == "__main__":
    review()
