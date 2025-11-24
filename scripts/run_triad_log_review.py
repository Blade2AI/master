import json
from datetime import datetime
from pathlib import Path
from typing import Dict, Any
from agi.core.agent_triad import run_triad_on_log

OUT_DIR = Path("logs/triad")
OUT_DIR.mkdir(parents=True, exist_ok=True)

import argparse
ap = argparse.ArgumentParser()
ap.add_argument("--input", required=True, help="Path to log file")
ap.add_argument("--model", help="Override TRIAD_MODEL_NAME")
args = ap.parse_args()

result: Dict[str, Any] = run_triad_on_log(args.input, model=args.model)

stamp = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
out_path = OUT_DIR / f"triad_review_{stamp}.jsonl"

with out_path.open("w", encoding="utf-8") as f:
    for issue in result.get("signals", []):
        f.write(json.dumps(issue, ensure_ascii=False) + "\n")

print(f"[triad] wrote {len(result.get('signals', []))} signals -> {out_path}")
