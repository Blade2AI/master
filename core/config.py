import os
from dataclasses import dataclass

@dataclass(frozen=True)
class GovernanceConfig:
    # --- HARD CONSTRAINTS (The Constitution) ---
    # Cannot be overridden by ENV to be unsafe, only tighter.
    GLOBAL_MAX_DAILY_COST: float = 50.0
    MAX_UNCERTAINTY: float = 0.4

    # --- PATHS ---
    DATA_DIR: str = "/app/data" if os.getenv("DOCKER_ENV") else "data"
    LEDGER_PATH: str = os.path.join(DATA_DIR, "boardroom_ledger.jsonl")
    STATE_PATH: str = os.path.join(DATA_DIR, "boardroom_state.json")

    # --- TRACKING ---
    TRACK: str = os.getenv("TRACK", "insider").lower()

    @classmethod
    def load(cls):
        # Validate that ENV doesn't try to override safety ceilings
        env_cost = float(os.getenv("GOV_MAX_COST", "50.0"))
        return cls(GLOBAL_MAX_DAILY_COST=min(env_cost, 50.0))

CONFIG = GovernanceConfig.load()
