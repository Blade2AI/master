import json
import os
from datetime import datetime

LOG_FILE = "Governance/Logs/audit-insider.jsonl"
REPORT_FILE = "readiness_report.json"

THRESHOLDS = {
    "evidence-validator": {"window_size": 50, "min_accuracy": 0.95, "min_samples": 10},
    "property-analyst": {"window_size": 30, "min_accuracy": 0.90, "min_samples": 10},
}

def load_logs(path):
    if not os.path.exists(path):
        return []
    entries = []
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                entries.append(json.loads(line))
            except Exception:
                pass
    return entries

def compute(entries):
    grouped = {k: [] for k in THRESHOLDS.keys()}
    for e in entries:
        fname = e.get('filename', '')
        if 'evidence' in fname.lower():
            grouped['evidence-validator'].append(e)
        elif 'prop' in fname.lower() or 'property' in fname.lower():
            grouped['property-analyst'].append(e)
    report = {}
    for agent, hist in grouped.items():
        cfg = THRESHOLDS[agent]
        recent = hist[-cfg['window_size']:]
        total = len(recent)
        approvals = sum(1 for x in recent if x.get('decision') == 'APPROVE')
        acc = approvals / total if total else 0.0
        ready = total >= cfg['min_samples'] and acc >= cfg['min_accuracy']
        report[agent] = {
            'status': 'READY_FOR_PROMOTION' if ready else 'CALIBRATING',
            'metrics': {
                'accuracy': round(acc, 3),
                'target_accuracy': cfg['min_accuracy'],
                'samples_collected': total,
                'samples_needed': cfg['min_samples'],
                'approvals': approvals,
                'rejections': total - approvals,
            },
            'last_updated': datetime.utcnow().isoformat() + 'Z'
        }
    return report

if __name__ == '__main__':
    logs = load_logs(LOG_FILE)
    if not logs:
        print('No insider audit logs found.')
        exit(0)
    rep = compute(logs)
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        json.dump(rep, f, indent=2)
    print(f"Report written to {REPORT_FILE}")
