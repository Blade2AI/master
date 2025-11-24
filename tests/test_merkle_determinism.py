import json
from pathlib import Path
import subprocess

def run(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True, shell=True)
    if result.returncode != 0:
        raise RuntimeError(result.stderr)
    return result.stdout.strip()

def test_merkle_root_is_deterministic(tmp_path):
    ledger_data = [
        {"event": "a", "value": 1},
        {"event": "b", "value": 2},
        {"event": "c", "value": 3},
    ]
    ledger_file = tmp_path / "ledger.json"
    ledger_file.write_text(json.dumps(ledger_data), encoding="utf-8")

    cmd = f"python scripts/compute_merkle_root.py \"{ledger_file}\""
    r1 = run(cmd)
    r2 = run(cmd)
    assert r1 == r2, "Merkle root should be deterministic for identical input"

    reversed_ledger = tmp_path / "ledger_reordered.json"
    ledger_data.reverse()
    reversed_ledger.write_text(json.dumps(ledger_data), encoding="utf-8")
    r3 = run(f"python scripts/compute_merkle_root.py \"{reversed_ledger}\"")
    assert r1 != r3, "Merkle root should change if order changes"
