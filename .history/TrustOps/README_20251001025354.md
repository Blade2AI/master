# TrustOps

Operational governance and trust scaffolding for the Sovereign Boardroom.

- Board: minutes and control packs
- Legal: deed specification, Protector appointment, Letter of Wishes
- Finance: Investment Policy Statement (IPS)
- Registers: Assets, Actions, Risks
- Ops: RACI and Ceri handover
- CODEX: mission anchor

## NHSBSA data request proforma (quickstart)

- Template: TrustOps/templates/NHSBSA_Proforma_Template.md
- Generator: TrustOps/scripts/new_nhsbsa_proforma.ps1
- VS Code Task: TrustOps: New NHSBSA proforma
- Output: TrustOps/out/nhsbsa/<date>-<title>.md

How to run

- From VS Code: Run Task → "TrustOps: New NHSBSA proforma" and fill prompts
- From terminal (PowerShell):
  - Example:
    - `powershell -NoProfile -ExecutionPolicy Bypass -File .\TrustOps\scripts\new_nhsbsa_proforma.ps1 -Title "My NHSBSA request" -Org "Example Org" -RequesterName "Name" -RequesterRole "LCFS" -ContactEmail "name@example.org" -Domain Prescription -Route "Ad hoc" -LawfulBasis "Public task" -Purpose "Purpose text" -Benefit "Benefit text" -DateFrom "2024-01-01" -DateTo "2024-12-31" -GeogScope "England" -DataCategory "Aggregated"`
  - Confirm output path is as expected: `TrustOps/out/nhsbsa/<date>-<title>.md`

Useful links

- Sitemap: https://www.nhsbsa.nhs.uk/sitemap
- Prescription data – Requesting our data: https://www.nhsbsa.nhs.uk/prescription-data/requesting-our-prescription-data
- Dental data – Requesting our data: https://www.nhsbsa.nhs.uk/dental-data/requesting-our-dental-data
- Ophthalmic data – Requesting our data: https://www.nhsbsa.nhs.uk/ophthalmic-data/requesting-our-ophthalmic-data
- Open Data Portal: https://www.nhsbsa.nhs.uk/access-our-data-products/open-data-portal-odp

Compliance note

- Cross-check if data is already published on dashboards or the Open Data Portal before requesting restricted extracts.
- Use a secure channel for dispatch (secure email/SFTP/portal) as per NHSBSA guidance.
