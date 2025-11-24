from __future__ import annotations
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Any

MANIFEST_FILE = Path("constitution/policy_manifest.yml")

try:
    import yaml  # type: ignore
except Exception:  # pragma: no cover
    yaml = None


@dataclass
class PolicyInfo:
    version: str
    files: Dict[str, str]  # path -> sha256


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def load_manifest() -> PolicyInfo:
    if not MANIFEST_FILE.exists():
        raise FileNotFoundError(f"Manifest not found: {MANIFEST_FILE}")
    if yaml is None:
        raise RuntimeError("PyYAML not installed. Install with: pip install pyyaml")
    data = yaml.safe_load(MANIFEST_FILE.read_text(encoding="utf-8"))
    return PolicyInfo(version=str(data.get("version","0.0.0")), files=dict(data.get("files", {})))


def compute_manifest_state(files: Dict[str, str]) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for rel, _ in files.items():
        p = Path(rel)
        if not p.exists():
            out[rel] = "MISSING"
        else:
            out[rel] = sha256_file(p)
    return out


def verify_manifest(pi: PolicyInfo) -> Dict[str, Any]:
    current = compute_manifest_state(pi.files)
    drift = {}
    for rel, expected_hash in pi.files.items():
        actual = current.get(rel)
        if actual != expected_hash:
            drift[rel] = {"expected": expected_hash, "actual": actual}
    return {"version": pi.version, "drift": drift}
