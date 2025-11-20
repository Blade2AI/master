# agi/core/assistant_channel.py
from __future__ import annotations
from typing import Dict, Any, List
import sqlite3
from .receipt import store_assistant_message, DB_PATH

ASSISTANT_SYSTEM_PROMPT = (
    "You are the Sovereign assistant channel.\n"
    "- You explain and discuss an existing Sovereign answer.\n"
    "- You MUST NOT change the core verdict.\n"
    "- If you detect a serious error or contradiction, say so and request a re-run.\n"
)

def get_assistant_system_prompt() -> str:
    return ASSISTANT_SYSTEM_PROMPT

def list_thread_messages(answer_id: str) -> List[Dict[str, Any]]:
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute(
        """
        SELECT role, message, created_at
        FROM assistant_messages
        WHERE answer_id = ?
        ORDER BY id ASC
        """,
        (answer_id,),
    )
    rows = cur.fetchall()
    conn.close()
    return [{"role": role, "message": msg, "created_at": created_at} for (role, msg, created_at) in rows]

def append_user_message(answer_id: str, receipt_id: str, message: str) -> None:
    store_assistant_message(answer_id, receipt_id, "user", message)

def append_assistant_message(answer_id: str, receipt_id: str, message: str) -> None:
    store_assistant_message(answer_id, receipt_id, "assistant", message)
