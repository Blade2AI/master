import sys
import os
import shutil
from pathlib import Path

sys.path.append(os.getcwd())
from src.core.router import SovereignRouter

INBOX_DIR = Path("Evidence/Inbox")
PROCESSED_DIR = Path("Evidence/Processed")


def process_inbox():
    try:
        router = SovereignRouter("evidence")
    except Exception as e:
        print(f"? FATAL: Router Init Failed: {e}")
        return
    print(f"?? Evidence Validator Online | Mode: {router.track.upper()}")
    INBOX_DIR.mkdir(parents=True, exist_ok=True)
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

    files = [f for f in INBOX_DIR.iterdir() if f.is_file() and f.name != ".gitkeep"]
    if not files:
        print("   ?? Inbox is empty. Add PDFs/Images to Evidence/Inbox/")
        return
    print(f"   Found {len(files)} documents to process...")

    for file_path in files:
        print(f"   Processing: {file_path.name}...")
        analyzed_data = {
            "source_file": file_path.name,
            "document_type": "Unclassified",
            "claim": "Pending Analysis",
            "risk_flags": ["MANUAL_REVIEW_REQUIRED"],
            "entities": [],
            "validation_status": "NEEDS_REVIEW" if router.track == "insider" else "VALID"
        }
        try:
            out_path = router.save_result(f"{file_path.stem}.json", analyzed_data)
            print(f"     ? Saved: {out_path}")
            shutil.move(str(file_path), str(PROCESSED_DIR / file_path.name))
        except Exception as e:
            print(f"     ? Failed: {e}")


if __name__ == "__main__":
    process_inbox()
