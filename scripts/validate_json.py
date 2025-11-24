#!/usr/bin/env python
import json, sys
from pathlib import Path
try:
    from jsonschema import validate
except ImportError:
    print("jsonschema module not installed. Install with: pip install jsonschema", file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 5 or '--schema' not in sys.argv or '--instance' not in sys.argv:
    print("Usage: python scripts/validate_json.py --schema <schema_file> --instance <json_file>")
    sys.exit(1)

schema_path = Path(sys.argv[sys.argv.index('--schema') + 1])
instance_path = Path(sys.argv[sys.argv.index('--instance') + 1])

if not schema_path.is_file():
    print(f"Schema not found: {schema_path}", file=sys.stderr); sys.exit(3)
if not instance_path.is_file():
    print(f"Instance not found: {instance_path}", file=sys.stderr); sys.exit(4)

schema = json.loads(schema_path.read_text(encoding='utf-8'))
instance = json.loads(instance_path.read_text(encoding='utf-8'))

try:
    validate(instance=instance, schema=schema)
except Exception as e:
    print(f"Validation FAILED: {e}", file=sys.stderr)
    sys.exit(5)

print("Validation OK: instance conforms to schema.")
