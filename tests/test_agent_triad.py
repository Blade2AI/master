import pytest
from agi.core.agent_triad import run_triad_on_log

SAMPLE_LOG = """
[2025-11-23T10:03:21Z] WARN ManifestCheck missing ParentSeal=@Blade040125 for /manifests/demo.json
[2025-11-23T10:04:02Z] INFO  Node PC4 health=OK
""".strip()

def test_triad_detects_missing_parent_seal(tmp_path):
    log_file = tmp_path / "sample.log"
    log_file.write_text(SAMPLE_LOG, encoding="utf-8")
    result = run_triad_on_log(str(log_file))
    signals = result["signals"]
    assert any(s["signal"] == "missing_parent_seal" for s in signals)
