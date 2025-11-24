# Regulator Portal Wireframe (Sovereign System)

## Layout Overview
- **Header:** Build ID, timestamp, environment, signature verification badge.
- **Filters:** Standard, clause, status (pass/warn/fail), date range.
- **Views:** Dashboard (summary tiles), Standards (matrix), Evidence Logs, Test Replay, Incidents.
- **Exports:** PDF / CSV / JSON of signed evidence bundles.

## ASCII Wireframe
```
+--------------------------------------------------------------------+
| Sovereign System | Build: 4421 | 2025-11-22T22:45Z | Signature: ? |
+--------------------------------------------------------------------+
| Dashboard | Standards | Evidence Logs | Test Replay | Incidents    |
+--------------------------------------------------------------------+
| EU Machinery 2023/1230   ? Pass      [Details]                     |
| ISO/TS 15066              ? Pass      [Details]                     |
| IEC 62443                 ?? Warn      [Details]                     |
| ISO 12100                 ? Pass      [Details]                     |
| IEC 61508                 ? Pass      [Details]                     |
| GDPR                      ? Pass      [Details]                     |
| NIS2                      ?? Warn      [Details]                     |
+--------------------------------------------------------------------+
| Tamper Evidence: Evidence2 Hash Diff ? | Evidence3 Modified ?      |
| Merkle Root Change ?                                                   |
+--------------------------------------------------------------------+
| Summary: 5 Pass | 2 Warn | 0 Fail                                     |
+--------------------------------------------------------------------+
```

## Drill-Down Evidence Panel
Each row links to a detail view containing:
- Standard & Clause
- Status history
- Signed artifact list
- Merkle delta (before/after root)
- Replay controls (re-run verification functions)

## API / Data Contracts
- `GET /api/compliance/summary` -> dashboard.yaml
- `GET /api/compliance/artifacts?standard=IEC_62443` -> evidence bundle
- `POST /api/compliance/replay` -> triggers verification harness

## Security & Integrity
- All JSON responses signed with node private key
- Signature + Merkle root validated client-side
- Audit log entry on each replay request

## Roadmap Enhancements
- Role-based access (Regulator / Operator / Auditor)
- Incremental evidence streaming (WebSocket)
- Multi-node aggregation view
