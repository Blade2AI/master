import os
import json
import shutil
from datetime import datetime

DRAFTS = "Property/Scored/_drafts"
PROD = "Property/Scored/_production"
AUDIT_LOG = "Governance/Logs/property_review.jsonl"

def log_action(filename: str, decision: str, payload: dict):
    os.makedirs(os.path.dirname(AUDIT_LOG), exist_ok=True)
    entry = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "event": "PROPERTY_REVIEW",
        "file": filename,
        "decision": decision,
        "data": payload
    }
    with open(AUDIT_LOG, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry) + "\n")

def review():
    if not os.path.exists(DRAFTS):
        print(f"??  No drafts folder: {DRAFTS}")
        return
    drafts = [f for f in os.listdir(DRAFTS) if f.endswith('.json')]
    if not drafts:
        print("? No property drafts pending.")
        return
    print(f"?? Found {len(drafts)} property leads for review.\n")
    for f in drafts:
        path = os.path.join(DRAFTS, f)
        with open(path, encoding="utf-8") as j:
            try:
                data = json.load(j)
            except json.JSONDecodeError:
                print(f"??  Corrupt JSON: {f}")
                continue
        print(f"?? {f}")
        print(f"   Addr:  {data.get('address')}")
        print(f"   Price: {data.get('asking_price')}")
        print(f"   Cond:  {data.get('condition_score')}/10")
        print(f"   Flags: {data.get('risk_flags')}")
        cmd = input("   [A]pprove / [R]eject / [S]kip? > ").strip().lower()
        if cmd == 'a':
            os.makedirs(PROD, exist_ok=True)
            shutil.move(path, os.path.join(PROD, f))
            log_action(f, "APPROVED", data)
            print("   ? Promoted to Production Portfolio.")
        elif cmd == 'r':
            os.remove(path)
            log_action(f, "REJECTED", data)
            print("   ? Rejected.")
        else:
            print("   ? Skipped.")
        print("-" * 30)

if __name__ == "__main__":
    review()
