#!/usr/bin/env bash
set -euo pipefail

echo "[sovereign] Initializing Constitution v0.1 spine..."

# Directories
mkdir -p core scout executor boardroom scripts src/core prompts Governance/Logs data

# Python package markers
for d in core scout executor boardroom src/core; do
  touch "$d/__init__.py"
done

# Kernel presence check
if [ ! -f src/core/router.py ]; then
  cat > src/core/router.py <<'EOF'
# Placeholder kernel. Replace with full SovereignRouter implementation.
from dataclasses import dataclass
@dataclass
class RouterResponse:
    path: str; status: str; audit_hash: str
EOF
fi

# Constitution config placeholder
if [ ! -f core/config.py ]; then
  cat > core/config.py <<'EOF'
import os
from dataclasses import dataclass
@dataclass(frozen=True)
class GovernanceConfig:
    GLOBAL_MAX_DAILY_COST: float = 50.0
    DATA_DIR: str = 'data'
CONFIG = GovernanceConfig()
EOF
fi

# Evidence validator system prompt
if [ ! -f prompts/evidence_validator_system.md ]; then
  cat > prompts/evidence_validator_system.md <<'EOF'
# Evidence Validator System Prompt v0.1
Principles:
- Treat all incoming documents as unverified.
- Extract claims verbatim; never infer hidden intent.
- Flag inconsistencies: prior decisions conflict, missing evidence, privilege concern.
- Redact PII (emails, phone numbers) unless required for governance.
Output JSON schema:
{
  "claims": ["string"],
  "flags": ["VALID"|"INCOMPLETE_EVIDENCE"|"CONTRADICTS_PRIOR"|"PRIVILEGE_CONCERN"],
  "redactions": ["original_fragment"],
  "confidence": 0.0-1.0
}
EOF
fi

# Sovereign CLI
if [ ! -f scripts/sovereign.sh ]; then
  cat > scripts/sovereign.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
CMD=${1:-help}
REPORT=readiness_report.json
LOG=Governance/Logs/audit-insider.jsonl

case "$CMD" in
  check)
    python scripts/analyze_rejections.py || echo "analysis failed"
    ;;
  promote)
    AGENT=${2:-}
    [ -z "$AGENT" ] && echo "usage: sovereign.sh promote <agent-name>" && exit 1
    [ ! -f "$REPORT" ] && echo "missing $REPORT. run check first." && exit 1
    STATUS=$(jq -r ".[\"$AGENT\"].status" "$REPORT" 2>/dev/null || echo none)
    if [ "$STATUS" = "READY_FOR_PROMOTION" ]; then
      echo "[promote] $AGENT -> stable"
      export TRACK=stable
    else
      echo "[deny] $AGENT status=$STATUS"
      exit 2
    fi
    ;;
  help|*)
    echo "sovereign.sh commands: check | promote <agent>"
    ;;
esac
EOF
  chmod +x scripts/sovereign.sh
fi

# Rejection analysis script
if [ ! -f scripts/analyze_rejections.py ]; then
  cat > scripts/analyze_rejections.py <<'EOF'
import json, os, collections, time
LOG_PATH = 'Governance/Logs/audit-insider.jsonl'
REPORT = 'readiness_report.json'
THRESHOLDS = {
  'evidence-validator': {'window_size':50,'min_accuracy':0.95,'min_samples':10},
  'property-analyst': {'window_size':30,'min_accuracy':0.90,'min_samples':10},
}

def load():
  if not os.path.exists(LOG_PATH): return []
  out=[]
  with open(LOG_PATH,'r') as f:
    for line in f:
      try: out.append(json.loads(line))
      except: pass
  return out

def classify_agent(entry):
  fn = entry.get('filename','').lower()
  if 'evidence' in fn: return 'evidence-validator'
  if 'property' in fn: return 'property-analyst'
  return None

def main():
  entries = load()
  if not entries:
    print('[analysis] no audit entries')
    return
  grouped = collections.defaultdict(list)
  for e in entries:
    ag = classify_agent(e)
    if ag: grouped[ag].append(e)
  report = {}
  for agent, hist in grouped.items():
    cfg = THRESHOLDS.get(agent, {'window_size':20,'min_accuracy':0.9,'min_samples':5})
    recent = hist[-cfg['window_size']:]
    approvals = sum(1 for x in recent if x.get('decision')=='APPROVE')
    rejections = sum(1 for x in recent if x.get('decision')=='REJECT')
    total = approvals + rejections
    acc = approvals/total if total else 0.0
    ready = total>=cfg['min_samples'] and acc>=cfg['min_accuracy']
    report[agent] = {
      'status': 'READY_FOR_PROMOTION' if ready else 'CALIBRATING',
      'metrics': {
        'accuracy': round(acc,3),
        'approvals': approvals,
        'rejections': rejections,
        'samples': total,
        'target_accuracy': cfg['min_accuracy']
      },
      'last_updated': time.strftime('%Y-%m-%dT%H:%M:%SZ')
    }
  with open(REPORT,'w') as f: json.dump(report,f,indent=2)
  for a,d in report.items():
    print(f"[agent] {a} status={d['status']} acc={d['metrics']['accuracy']} samples={d['metrics']['samples']}")

if __name__=='__main__':
  main()
EOF
fi

echo "[sovereign] Scaffold complete. Run: export TRACK=insider; python scripts/validate_governance.py"
