"""Build txtai index from a manifest of files. Minimal v0.1.
Assumes a text manifest file listing absolute paths one per line.
"""
from txtai.embeddings import Embeddings
from pathlib import Path
import argparse, json, hashlib

parser = argparse.ArgumentParser()
parser.add_argument('--manifest', required=True, help='Path to file listing source documents')
parser.add_argument('--indexdir', default=r'C:\EliteTruthEngine\elite-truth-index')
args = parser.parse_args()

indexdir = Path(args.indexdir)
indexdir.mkdir(parents=True, exist_ok=True)

embeddings = Embeddings({'path': 'sentence-transformers/all-MiniLM-L6-v2'})

docs = []
manifest_path = Path(args.manifest)
for line in manifest_path.read_text(encoding='utf-8').splitlines():
    line = line.strip()
    if not line or line.startswith('#'): continue
    p = Path(line)
    if not p.exists():
        print(f'[skip missing] {p}')
        continue
    text = p.read_text(errors='ignore')
    doc_id = hashlib.sha256(p.as_posix().encode()).hexdigest()[:16]
    docs.append({'id': doc_id, 'text': text, 'file': p.as_posix()})

if not docs:
    print('No documents ingested. Exiting.')
    raise SystemExit(0)

embeddings.index(docs)
embeddings.save(indexdir.as_posix())

with (indexdir / 'build_meta.json').open('w', encoding='utf-8') as f:
    json.dump({'source_count': len(docs)}, f, indent=2)
print(f'Indexed {len(docs)} documents -> {indexdir}')
