# Metrics and Fleet Overview

This document captures the operational setup for metrics management and fleet health within Sovereign System.

1. Metrics configuration
- Config path: `config/metrics_config.yaml`
- Key fields:
  - `logs_root`: `C:\BladeOps\data\metrics\raw`
  - `raw_file`: `success_rate.log`
  - `summary_dir`: `C:\BladeOps\data\metrics\summary`
  - Rotation: `max_file_size_mb`, `rotate_interval`, `max_days`
  - Retention: `raw_retention_days`, `compress_old_raw`
  - Aggregation: `aggregation_interval`, `alert_if_success_rate_below`

2. Rotation + aggregation script
- Script: `scripts/Manage-Metrics.ps1`
- Responsibilities:
  - Rotate active raw file if `max_file_size_mb` or `max_days` exceeded.
  - Aggregate window statistics (total, success, fail, success_rate) into `success_rate_summary.csv` in `summary_dir`.
  - Apply retention: delete or gzip raw files older than `raw_retention_days`.
  - Update integrity manifest with SHA-256 of latest raw and summary.

3. Metrics integrity manifest
- Path: `C:\BladeOps\data\metrics\metrics_manifest.json`
- Content: array of entries
  - `path`, `sha256`, `size_bytes`, `timestamp`
- Verification harness can include the manifest as evidence by setting env `HARNESS_INCLUDE_METRICS_MANIFEST=1` (or provide a path via `METRICS_MANIFEST_PATH`).

4. Fleet health
- Fleet config: `C:\BladeOps\config\fleet_nodes.json`
- Health check script: `C:\BladeOps\scripts\RUN-SovereignHealthCheck.ps1`
- Output: `C:\BladeOps\data\health\latest_health.json`
- Logic: critical node down => `CRITICAL`; only non-critical down => `DEGRADED`; otherwise `HEALTHY`.

5. Scheduling
- Register a Windows Task (PC4): "Sovereign – Manage Metrics"
  - Trigger: every 15–60 minutes
  - Action: `pwsh C:\BladeOps\scripts\Manage-Metrics.ps1 -ConfigPath C:\Users\andyj\source\repos\PrecisePointway\master\config\metrics_config.yaml`
- Optional: schedule `RUN-SovereignHealthCheck.ps1` similarly (every 5–10 minutes).

6. Manual run
- `pwsh C:\BladeOps\scripts\Manage-Metrics.ps1 -Verbose`
- `pwsh C:\BladeOps\scripts\RUN-SovereignHealthCheck.ps1`
