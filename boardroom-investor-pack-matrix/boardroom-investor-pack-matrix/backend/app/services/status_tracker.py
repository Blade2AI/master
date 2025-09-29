from fastapi import BackgroundTasks
from typing import Dict, Any
import time

class StatusTracker:
    def __init__(self):
        self.status = "Not Started"
        self.progress = 0

    def start_tracking(self):
        self.status = "In Progress"
        self.progress = 0
        self._simulate_progress()

    def _simulate_progress(self):
        for i in range(1, 11):
            time.sleep(1)  # Simulate time-consuming task
            self.progress = i * 10
        self.status = "Completed"

    def get_status(self) -> Dict[str, Any]:
        return {
            "status": self.status,
            "progress": self.progress
        }

status_tracker = StatusTracker()

def track_status(background_tasks: BackgroundTasks):
    background_tasks.add_task(status_tracker.start_tracking)