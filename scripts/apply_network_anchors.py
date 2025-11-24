"""Apply network anchors (IPFS via nft.storage, Arweave via Bundlr stub) to anchor JSON.

Requirements:
  pip install requests
Environment:
  NFT_STORAGE_API_KEY
  BUNDLR_NODE_URL (stub; real upload not implemented)
"""
import argparse
import json
import os
from pathlib import Path
import requests

def load_anchor(path: Path) -> dict:
    with path.open('r', encoding='utf-8') as f:
        return json.load(f)

def save_anchor(path: Path, data: dict) -> None:
    tmp = path.with_suffix(path.suffix + '.tmp')
    with tmp.open('w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, sort_keys=True)
    tmp.replace(path)

def upload_to_nft_storage(anchor_bytes: bytes) -> str:
    api_key = os.environ.get('NFT_STORAGE_API_KEY')
    if not api_key:
        raise RuntimeError('NFT_STORAGE_API_KEY not set')
    resp = requests.post(
        'https://api.nft.storage/upload',
        headers={'Authorization': f'Bearer {api_key}'},
        files={'file': ('anchor.json', anchor_bytes, 'application/json')},
        timeout=30,
    )
    resp.raise_for_status()
    data = resp.json()
    cid = data.get('value', {}).get('cid')
    if not cid:
        raise RuntimeError(f'Unexpected nft.storage response: {data}')
    return cid

def upload_to_arweave_via_bundlr(anchor_bytes: bytes) -> str:
    # Stub – implement per Bundlr API/CLI
    node_url = os.environ.get('BUNDLR_NODE_URL')
    if not node_url:
        raise RuntimeError('BUNDLR_NODE_URL not set')
    raise NotImplementedError('Bundlr upload not implemented')

def main():
    parser = argparse.ArgumentParser(description='Apply network anchors to anchor JSON.')
    parser.add_argument('--anchor', required=True, type=Path)
    args = parser.parse_args()

    anchor = load_anchor(args.anchor)
    anchor_bytes = json.dumps(anchor, separators=(',', ':'), sort_keys=True).encode('utf-8')

    # IPFS
    try:
        cid = upload_to_nft_storage(anchor_bytes)
        print(f'IPFS CID: {cid}')
        anchor.setdefault('backends', {}).setdefault('ipfs', {})
        anchor['backends']['ipfs'].update({'enabled': True, 'cid': cid, 'provider': 'nft.storage'})
    except Exception as e:
        print(f'[IPFS] Upload failed: {e}')

    # Arweave (stub)
    if os.environ.get('BUNDLR_NODE_URL'):
        try:
            tx_id = upload_to_arweave_via_bundlr(anchor_bytes)
            print(f'Arweave TXID: {tx_id}')
            anchor.setdefault('backends', {}).setdefault('arweave', {})
            anchor['backends']['arweave'].update({'enabled': True, 'tx_id': tx_id, 'bundlr_node': os.environ.get('BUNDLR_NODE_URL')})
        except NotImplementedError:
            print('[ARWEAVE] Bundlr upload not implemented; skipping.')
        except Exception as e:
            print(f'[ARWEAVE] Upload failed: {e}')

    save_anchor(args.anchor, anchor)
    print('Anchor updated with network receipts (where available).')

if __name__ == '__main__':
    main()
