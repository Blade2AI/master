import json
from uuid import uuid4
from pathlib import Path
import yaml
import time

class Recorder:
    def __init__(self, config_path='config/recorder_config.yaml'):
        with open(config_path, 'r', encoding='utf-8') as f:
            self.config = yaml.safe_load(f)
        self.ledger_path = Path(self.config['ledger_path'])
        self.node_id = self.config['node_id']
        self.schema_version = self.config['schema_version']
        self.ledger_path.parent.mkdir(parents=True, exist_ok=True)

    def log_event(self, event_type, payload):
        event = {
            'event_id': str(uuid4()),
            'event_type': event_type,
            'schema_version': self.schema_version,
            'node_id': self.node_id,
            'timestamp': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
            'payload': payload
        }
        with open(self.ledger_path, 'a', encoding='utf-8') as f:
            f.write(json.dumps(event, ensure_ascii=False) + '\n')
        return event

if __name__ == '__main__':
    import sys
    if '--smoke-test' in sys.argv:
        recorder = Recorder()
        for i in range(20):
            recorder.log_event('test', {'index': i})
        print(f"Smoke test complete. Check {recorder.ledger_path}")
