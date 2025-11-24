import json
from pathlib import Path
import pytest

FORBIDDEN_KEYS = {
    "name",
    "full_name",
    "first_name",
    "last_name",
    "email",
    "phone",
    "phone_number",
    "address",
    "ip",
    "ip_address",
    "user_id",
    "username",
    "case_id",
    "nhs_number",
    "dob",
    "date_of_birth"
}

ANCHOR_FILES = [
    Path("tests/samples/sample_event_anchor.json"),
]

def walk_json(obj, path=None):
    if path is None:
        path = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            current_path = path + [k]
            yield current_path, k, v
            yield from walk_json(v, current_path)
    elif isinstance(obj, list):
        for idx, v in enumerate(obj):
            current_path = path + [str(idx)]
            yield from walk_json(v, current_path)

@pytest.mark.parametrize("anchor_path", ANCHOR_FILES)
def test_anchor_contains_no_personal_keys(anchor_path: Path):
    assert anchor_path.is_file(), f"Anchor file not found: {anchor_path}"
    data = json.loads(anchor_path.read_text(encoding="utf-8"))
    violations = []
    for key_path, key, value in walk_json(data):
        key_lower = key.lower()
        if key_lower in FORBIDDEN_KEYS:
            violations.append({
                "path": ".".join(key_path),
                "key": key,
                "value": value,
            })
    if violations:
        lines = [f"- {v['path']} (key='{v['key']}', value={repr(v['value'])})" for v in violations]
        details = "\n".join(lines)
        pytest.fail(
            "GDPR guard violation: forbidden personal-data-like keys found:\n" + details
        )
