#!/usr/bin/env python3
"""
Verify-Evidence.py
Scan a directory of JSON artifacts (Projects, Meetings, SIF) and verify signatures and hashes.
Produces a JSONL report per artifact and a summary.
"""
import argparse
import json
import os
import hashlib
from typing import Dict, Any

# Reuse policy_signature verification if available; fallback to simple RSA via xml (PowerShell uses RSA XML)
try:
    from agi.core.policy_signature import verify_signature as verify_sig_core
except Exception:
    verify_sig_core = None


def sha256_of_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        while True:
            chunk = f.read(8192)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def load_json(path: str) -> Any:
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)


def verify_signature_with_core(obj: Dict[str, Any], pubkey_path: str) -> (bool, str):
    if not verify_sig_core:
        return False, 'verify_sig_core not available'
    try:
        return verify_sig_core(obj, pubkey_path), 'OK' if verify_sig_core(obj, pubkey_path) else 'Invalid'
    except Exception as e:
        return False, f'Error: {e}'


def verify_signature_ps(obj: Dict[str, Any], pubkey_path: str) -> (bool, str):
    # Fallback: call Verify-MessageSignature.ps1 via subprocess if PowerShell available
    import subprocess, tempfile
    tmpf = tempfile.NamedTemporaryFile(delete=False, suffix='.json')
    try:
        tmpf.write(json.dumps(obj, separators=(',',':')).encode('utf-8'))
        tmpf.close()
        cmd = ["powershell", "-NoProfile", "-Command", f"& '{os.path.abspath('scripts/signature/Verify-MessageSignature.ps1')}' -Data '{tmpf.name}' -PublicKeyPath '{pubkey_path}' | ConvertTo-Json -Compress"]
        out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, universal_newlines=True)
        res = json.loads(out)
        return res.get('valid', False), res.get('reason', '')
    except Exception as e:
        return False, f'PS verify error: {e}'
    finally:
        try:
            os.unlink(tmpf.name)
        except Exception:
            pass


def verify_artifact(path: str, pubkey_path: str) -> Dict[str, Any]:
    report = {'path': path, 'signature_ok': None, 'signature_reason': None, 'hash_ok': None, 'hash_value': None}
    try:
        obj = load_json(path)
    except Exception as e:
        report['error'] = f'JSON load error: {e}'
        return report

    # compute file hash
    try:
        report['hash_value'] = sha256_of_file(path)
        report['hash_ok'] = True
    except Exception as e:
        report['hash_ok'] = False
        report['hash_error'] = str(e)

    # verify signature
    if verify_sig_core:
        ok, reason = verify_signature_with_core(obj, pubkey_path)
    else:
        ok, reason = verify_signature_ps(obj, pubkey_path)
    report['signature_ok'] = ok
    report['signature_reason'] = reason
    return report


def scan_directory(root: str, pubkey_path: str, out_file: str):
    reports = []
    for dirpath, dirnames, filenames in os.walk(root):
        for fname in filenames:
            if fname.lower().endswith('.json'):
                p = os.path.join(dirpath, fname)
                r = verify_artifact(p, pubkey_path)
                reports.append(r)
                with open(out_file, 'a', encoding='utf-8') as of:
                    of.write(json.dumps(r) + '\n')
    # summary
    summary = {
        'scanned': len(reports),
        'valid_signatures': sum(1 for r in reports if r.get('signature_ok')),
        'invalid_signatures': sum(1 for r in reports if r.get('signature_ok') is False),
        'hash_failures': sum(1 for r in reports if r.get('hash_ok') is False)
    }
    return summary


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', default='C:/BladeOps', help='Root path to scan')
    parser.add_argument('--pubkey', default='C:/BladeOps/Security/public_key.xml', help='Public key path')
    parser.add_argument('--out', default='verify_report.jsonl', help='Output report JSONL')
    args = parser.parse_args()

    if os.path.exists(args.out):
        os.remove(args.out)

    summary = scan_directory(args.root, args.pubkey, args.out)
    print(json.dumps(summary, indent=2))

if __name__ == '__main__':
    main()
