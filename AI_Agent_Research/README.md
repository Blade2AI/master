# AI Agent Research Sandbox

This folder is a **Python sandbox** for small AI/agent experiments.
Nothing here is production; it is where ideas get tested before they
graduate into real services.

## Setup

From the repo root:

```
cd AI_Agent_Research
python -m venv .venv
# Windows
./.venv/Scripts/activate
# macOS / Linux
# source .venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt
```

## Quick environment check

```
python src/env_check.py
```

* If you see `Result: environment READY for sandbox use.`, you’re good.
* If any libraries are marked `[MISSING]`, fix them before wasting time
  debugging agent code.

## Notebook usage

Launch Jupyter:

```
jupyter notebook
```

Open:

* `src/agent_playground.ipynb`

Use this notebook for:

* small HTTP calls to local or remote models,
* quick agent loop prototypes,
* scratchpad experiments you may later promote into proper modules.

## Notes

* Do **not** put real secrets in this repo or in notebooks.
* Anything that works well here should be moved into your main
  codebase with tests, logging, and proper guardrails.
