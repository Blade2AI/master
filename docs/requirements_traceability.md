# Requirements Traceability Matrix (Initial Scaffold)

| Standard | Clause | Description | Verification Script | Artifact Path | Status |
|----------|--------|-------------|---------------------|---------------|--------|
| EU_Machinery_2023_1230 | 1.1 | Safety governance logging | VerificationHarness.ps1 -Safety | logs/compliance/machinery.json | pending |
| ISO_TS_15066 | 4.2 | Collaborative robot risk evidence | VerificationHarness.ps1 -Robotics | logs/compliance/robotics.json | pending |
| IEC_62443 | 2.3 | Network zone integrity | VerificationHarness.ps1 -Network | logs/compliance/62443.json | pending |
| ISO_12100 | 5.1 | Risk assessment artifact chain | VerificationHarness.ps1 -Risk | logs/compliance/12100.json | pending |
| IEC_61508 | 7.4 | Functional safety proof bundle | VerificationHarness.ps1 -SafetyFunc | logs/compliance/61508.json | pending |
| GDPR | Art.30 | Processing record tamper evidence | VerificationHarness.ps1 -GDPR | logs/compliance/gdpr.json | pending |
| NIS2 | Sec.17 | Incident response readiness log | VerificationHarness.ps1 -NIS2 | logs/compliance/nis2.json | pending |

> Populate scripts and automate Merkle + signature validation per artifact. Each row should link to a signed JSON including per-evidence hash and verification outcome.
