[CmdletBinding()]
param(
  [string]$ManifestPath = "constitution/policy_manifest.yml",
  [string]$PrivateKeyPem = "$env:USERPROFILE/.sovereign/policy_signing_key.pem",
  [switch]$CreateKey
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-Dir($p){ if (-not [string]::IsNullOrWhiteSpace($p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }

# Ensure PyYAML available note for users
Write-Host "[INFO] This script expects Python with PyYAML and cryptography installed." -ForegroundColor Cyan
Write-Host "       pip install pyyaml cryptography" -ForegroundColor Cyan

if ($CreateKey) {
  $keyDir = Split-Path -Parent $PrivateKeyPem
  New-Dir $keyDir
  python - << 'PY'
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend
import os

key = rsa.generate_private_key(public_exponent=65537, key_size=4096, backend=default_backend())
priv = key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.TraditionalOpenSSL,
    encryption_algorithm=serialization.NoEncryption(),
)
with open(r"$PrivateKeyPem","wb") as f:
    f.write(priv)
with open(r"$PrivateKeyPem.pub","wb") as f:
    f.write(key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    ))
print("Created keypair:", r"$PrivateKeyPem", "and .pub")
PY
  return
}

python - << 'PY'
import sys, json, hashlib, yaml, pathlib
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.backends import default_backend

manifest_path = pathlib.Path(r"$ManifestPath")
key_path = pathlib.Path(r"$PrivateKeyPem")

if not manifest_path.exists():
    print("Manifest not found:", manifest_path)
    sys.exit(2)

manifest = yaml.safe_load(manifest_path.read_text(encoding="utf-8"))
files = manifest.get("files", {})

# Compute combined hash of all tracked files in manifest order
h = hashlib.sha256()
for rel in sorted(files.keys()):
    p = pathlib.Path(rel)
    if not p.exists():
        print("Missing:", rel)
        sys.exit(3)
    h.update(p.read_bytes())
combined = h.digest()

if not key_path.exists():
    print("Private key not found:", key_path)
    sys.exit(4)

priv = serialization.load_pem_private_key(key_path.read_bytes(), password=None, backend=default_backend())
signature = priv.sign(
    combined,
    padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.MAX_LENGTH),
    hashes.SHA256(),
)
manifest["signature"] = signature.hex()
manifest_path.write_text(yaml.safe_dump(manifest, sort_keys=False), encoding="utf-8")
print("Signed manifest.")
PY
