# DAY 1 – SOVEREIGN AGENT DEPLOYMENT CHECKLIST

- [ ] Git clean; Docker running; Python 3.10+; Node/npm present
- [ ] Constitution present: `src/core/config.py`, `src/core/router.py`
- [ ] Tools present: `scripts/calculate_readiness.py`, `scripts/review_property.py`
- [ ] Orchestrator present: `scripts/orchestrate_system.sh`

## 1) Create directories
- [ ] Evidence/Inbox, Evidence/Analysis/_drafts, Evidence/Analysis/_verified
- [ ] Property/Leads, Property/Scored/_drafts, Property/Scored/_production
- [ ] Governance/Logs

## 2) .env (Insider default)
- [ ] TRACK=insider
- [ ] EVIDENCE_TRACK=insider
- [ ] PROPERTY_TRACK=insider

## 3) Bring up containers
- [ ] docker-compose build && docker-compose up -d

## 4) Generate drafts
- [ ] Add PDFs/images to Evidence/Inbox
- [ ] Run evidence and property agents

## 5) Review drafts
- [ ] Approve/Reject via console or extension
- [ ] Audit log lines added to Governance/Logs/audit-insider.jsonl

## 6) Readiness
- [ ] Run `python scripts/calculate_readiness.py`
- [ ] Report exists and accuracy shown

## Exit criteria
- [ ] Router writes only to _drafts in Insider
- [ ] Audit log exists and increments
- [ ] Readiness shows CALIBRATING (expected Day 1)
