#!/usr/bin/env python3
import json
import os
import subprocess
from pathlib import Path

REPORT = Path("Governance/healthcheck_report.json")


def docker_ps():
    try:
        p = subprocess.run(["docker", "ps", "--format", "{{.Names}}:::{{.Status}}"], capture_output=True, text=True)
        names = {}
        for line in p.stdout.strip().splitlines():
            if ":::" in line:
                n, s = line.split(":::", 1)
                names[n] = s
        return names
    except FileNotFoundError:
        return {"status": "Docker not available"}


def check_ledger():
    logs = {
        "audit_chain": Path("Governance/Logs/audit_chain.jsonl").exists(),
    }
    return logs


def main():
    report = {
        "containers": docker_ps(),
        "ledgers": check_ledger(),
    }
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(report, indent=2))
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
