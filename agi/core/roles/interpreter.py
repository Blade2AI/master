# agi/core/roles/interpreter.py
from __future__ import annotations
from typing import Dict, Any

def build_interpreter_prompt(question: str, raw_answer: str) -> str:
    return (
        "You are an interpreter. Your job is to explain the given answer in simple, "
        "clear language without changing its meaning or introducing new facts.\n\n"
        f"Question:\n{question}\n\n"
        f"Answer:\n{raw_answer}\n\n"
        "Now explain this to a non-technical person in a short, concrete way."
    )

def run_interpreter(question: str, raw_answer: str, context: Dict[str, Any]) -> Dict[str, Any]:
    """Stub implementation for v0.1a. Replace with real LLM call."""
    prompt = build_interpreter_prompt(question, raw_answer)
    explained = f"[INTERPRETED] {raw_answer}"
    return {"role": "interpreter", "prompt": prompt, "explained_answer": explained}
