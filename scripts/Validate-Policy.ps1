[CmdletBinding()]
param(
  [string]$ManifestPath = "constitution/policy_manifest.yml",
  [string]$PublicKeyPem = "$env:USERPROFILE/.sovereign/policy_signing_key.pem.pub"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "[INFO] Validating policy manifest signature and drift" -ForegroundColor Cyan

python - << 'PY'
import sys, hashlib, yaml, pathlib
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.backends import default_backend

manifest_path = pathlib.Path(r"$ManifestPath")
key_path = pathlib.Path(r"$PublicKeyPem")

if not manifest_path.exists():
    print("Manifest not found:", manifest_path)
    sys.exit(2)

m = yaml.safe_load(manifest_path.read_text(encoding="utf-8"))
files = m.get("files", {})
signature_hex = (m.get("signature") or "").strip()
if not signature_hex:
    print("No signature in manifest.")
    sys.exit(3)

# Compute combined hash
h = hashlib.sha256()
missing = []
for rel in sorted(files.keys()):
    p = pathlib.Path(rel)
    if not p.exists():
        missing.append(rel)
    else:
        h.update(p.read_bytes())
combined = h.digest()

if missing:
    print("Missing files:", ", ".join(missing))
    sys.exit(4)

pub = serialization.load_pem_public_key(key_path.read_bytes(), backend=default_backend())
try:
    pub.verify(bytes.fromhex(signature_hex), combined, padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.MAX_LENGTH), hashes.SHA256())
    print("OK: Signature valid.")
except Exception as e:
    print("FAIL: Signature invalid:", e)
    sys.exit(5)

print("OK: Policy files accounted for and signed.")
PY
