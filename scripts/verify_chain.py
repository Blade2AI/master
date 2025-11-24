#!/usr/bin/env python
"""Dual-chain verifier (local simulation / future remote).
Verifies sequential anchor payloads (6-line text format):
  line0: root_hash (128 hex chars or 64 if single-hash)
  line1: timestamp (ISO8601 UTC)
  line2: node_id
  line3: protocol/version tag
  line4: previous_arweave_tx_id (64 hex or all zeros for genesis)
  line5: previous_ipfs_cid (64 hex or all zeros for genesis)

Local mode: point to a directory of *.anchor.txt files. Each file name (sans extension)
acts as BOTH arweave_tx_id and ipfs_cid for simplification.

Chain termination is a zero-root (all zeros) OR end of files.
Exit codes:
 0 success
 1 structural error
 2 link mismatch
 3 empty directory / no anchors
"""
from __future__ import annotations
import sys, re
from pathlib import Path
from dataclasses import dataclass

ROOT_RE_64 = re.compile(r"^[0-9a-f]{64}$")
ROOT_RE_128 = re.compile(r"^[0-9a-f]{128}$")
HEX64 = re.compile(r"^[0-9a-f]{64}$")
ALL_ZERO_64 = "0" * 64
ALL_ZERO_128 = "0" * 128

@dataclass
class Anchor:
    file: Path
    arweave_id: str
    ipfs_id: str
    root: str
    prev_ar: str
    prev_ipfs: str
    zero_root: bool

def load_anchor(p: Path) -> Anchor:
    lines = p.read_text(encoding="utf-8").splitlines()
    if len(lines) < 6:
        raise ValueError(f"Anchor file {p} has {len(lines)} lines < 6")
    root = lines[0].strip().lower()
    prev_ar = lines[4].strip().lower()
    prev_ip = lines[5].strip().lower()
    zero_root = root in (ALL_ZERO_64, ALL_ZERO_128)
    if not (ROOT_RE_64.match(root) or ROOT_RE_128.match(root)):
        raise ValueError(f"Invalid root hash format in {p}: {root}")
    if not (prev_ar == ALL_ZERO_64 or HEX64.match(prev_ar)):
        raise ValueError(f"Invalid previous arweave id in {p}: {prev_ar}")
    if not (prev_ip == ALL_ZERO_64 or HEX64.match(prev_ip)):
        raise ValueError(f"Invalid previous ipfs id in {p}: {prev_ip}")
    # Use filename stem as both ids in local simulation
    stem_hex = (p.stem * 2)[:64]  # simplistic placeholder if not real hex
    pseudo_id = stem_hex if HEX64.match(stem_hex) else ("deadbeef" * 8)[:64]
    return Anchor(file=p, arweave_id=pseudo_id, ipfs_id=pseudo_id,
                  root=root, prev_ar=prev_ar, prev_ipfs=prev_ip, zero_root=zero_root)

def verify_chain(dir_path: Path) -> int:
    anchors = sorted(dir_path.glob("*.anchor.txt"))
    if not anchors:
        print("[ERROR] No anchor files found", file=sys.stderr)
        return 3
    chain = [load_anchor(a) for a in anchors]
    # Verify forward links
    for idx, a in enumerate(chain):
        if idx == 0:
            # genesis must point to zeros
            if a.prev_ar != ALL_ZERO_64 or a.prev_ipfs != ALL_ZERO_64:
                print(f"[ERROR] Genesis anchor {a.file.name} does not point to zero previous IDs", file=sys.stderr)
                return 2
        else:
            prev = chain[idx - 1]
            if a.prev_ar != prev.arweave_id or a.prev_ipfs != prev.ipfs_id:
                print(f"[ERROR] Link mismatch at {a.file.name}: expected prev {prev.arweave_id}/{prev.ipfs_id} got {a.prev_ar}/{a.prev_ipfs}", file=sys.stderr)
                return 2
        print(f"[OK] {a.file.name} root={a.root[:12]} prev={a.prev_ar[:12]} zero_root={a.zero_root}")
        if a.zero_root:
            print("[TERMINUS] Zero-root reached; chain integrity verified.")
            return 0
    print("[WARN] Chain ended without zero-root terminus (acceptable if not erased yet).")
    return 0

def main():
    if len(sys.argv) != 2:
        print("Usage: python scripts/verify_chain.py <anchor_dir>")
        sys.exit(1)
    dir_path = Path(sys.argv[1])
    if not dir_path.is_dir():
        print(f"[ERROR] Not a directory: {dir_path}", file=sys.stderr)
        sys.exit(1)
    code = verify_chain(dir_path)
    sys.exit(code)

if __name__ == '__main__':
    main()
