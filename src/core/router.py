import os
import json
import time
from pathlib import Path
from src.core.config import CONFIG

class SovereignRouter:
    def __init__(self, agent_name: str):
        self.agent_name = agent_name.lower()
        # Resolve per-agent track (EVIDENCE_TRACK / PROPERTY_TRACK / fallback TRACK)
        self.track = CONFIG.get_agent_track(agent_name)

        # Jurisdiction roots (container volume mounts expected)
        root_prefix = Path(os.environ.get("SOVEREIGN_ROOT", "/data"))
        
        if self.agent_name == "evidence":
            self.base_root = root_prefix / "Evidence" if os.environ.get("SOVEREIGN_ROOT") else Path("/data/evidence")
            # Fix for local vs docker path structure mismatch if needed, but let's assume structure matches
            if os.environ.get("SOVEREIGN_ROOT"):
                 self.base_root = root_prefix / "Evidence"
            
            self.output_dirs = {
                "insider": self.base_root / "Analysis" / "_drafts",
                "stable": self.base_root / "Analysis" / "_verified",
            }
        elif self.agent_name == "property":
            self.base_root = root_prefix / "Property" if os.environ.get("SOVEREIGN_ROOT") else Path("/data/property")
            if os.environ.get("SOVEREIGN_ROOT"):
                 self.base_root = root_prefix / "Property"

            self.output_dirs = {
                "insider": self.base_root / "Scored" / "_drafts",
                "stable": self.base_root / "Scored" / "_production",
            }
        else:
            # Generic fallback pattern for new agents
            self.base_root = Path(f"/data/{self.agent_name}")
            self.output_dirs = {
                "insider": self.base_root / "Output" / "_drafts",
                "stable": self.base_root / "Output" / "_prod",
            }

        self.target_dir = self.output_dirs.get(self.track)
        if self.target_dir is None:
            # Fail safe: revert to insider
            self.track = "insider"
            self.target_dir = self.output_dirs["insider"]

        self.target_dir.mkdir(parents=True, exist_ok=True)

    def get_execution_mode(self) -> str:
        return "SANDBOX" if self.track == "insider" else "LIVE"

    def log_event(self, event_type: str, details: dict):
        # Use SOVEREIGN_ROOT if available
        root_prefix = Path(os.environ.get("SOVEREIGN_ROOT", "."))
        log_dir = root_prefix / "Governance" / "Logs"
        log_dir.mkdir(parents=True, exist_ok=True)
        log_file = log_dir / "audit_chain.jsonl"
        
        event = {
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "agent": self.agent_name,
            "track": self.track,
            "type": event_type,
            "details": details,
            "hash": "pending" 
        }
        
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(json.dumps(event) + "\n")

    def process(self, filename: str, data: dict, confidence: float = 1.0, estimated_cost: float = 0.0):
        self.save_result(filename, data)
        self.log_event("PROCESS_COMPLETED", {
            "filename": filename,
            "confidence": confidence,
            "cost": estimated_cost
        })

    def save_result(self, filename: str, data: dict) -> str:
        status = "PENDING_REVIEW" if self.track == "insider" else "AUTO_VERIFIED"
        data["_governance"] = {
            "track": self.track,
            "agent_name": self.agent_name,
            "status": status,
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
        }
        safe_filename = Path(filename).name
        output_path = self.target_dir / safe_filename
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        print(f"[{self.agent_name.upper()} | {self.track.upper()}] Saved -> {output_path}")
        return str(output_path)
