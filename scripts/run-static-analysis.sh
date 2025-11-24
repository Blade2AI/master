#!/usr/bin/env bash
set -euo pipefail

echo "[StaticAnalysis] Starting cppcheck run (verification scope)"

if ! command -v cppcheck >/dev/null 2>&1; then
  echo "[StaticAnalysis] ERROR: cppcheck not found. Install via package manager (e.g. apt install cppcheck / brew install cppcheck)" >&2
  exit 2
fi

REPORT_DIR="build"
REPORT_XML="${REPORT_DIR}/cppcheck_report.xml"
REPORT_TXT="${REPORT_DIR}/cppcheck_summary.txt"
mkdir -p "${REPORT_DIR}"

# Use config file if present
CFG_FILE=".cppcheck"
CFG_ARGS=""
if [[ -f "${CFG_FILE}" ]]; then
  echo "[StaticAnalysis] Using configuration file ${CFG_FILE}";
  # Extract lines that start with -- or -i etc (simple parser)
  CFG_ARGS=$(grep -E '^(-|--)' "${CFG_FILE}" || true)
fi

# Run cppcheck focusing on verifier sources
# --xml + --xml-version for machine-readable output; error-exitcode=1 to fail CI on issues
set +e
cppcheck \
  --xml --xml-version=2 \
  --enable=all \
  --error-exitcode=1 \
  ${CFG_ARGS} \
  src/verifier 2>"${REPORT_XML}"
STATUS=$?
set -e

# Summarize findings
if [[ ${STATUS} -eq 0 ]]; then
  echo "[StaticAnalysis] PASS: No high severity issues detected." | tee "${REPORT_TXT}"
else
  echo "[StaticAnalysis] FAIL: Issues detected. See ${REPORT_XML}" | tee "${REPORT_TXT}"
fi

# Optional: print concise summary from XML (warnings count)
if command -v xmllint >/dev/null 2>&1; then
  COUNT=$(xmllint --xpath 'count(/results/errors/error)' "${REPORT_XML}" 2>/dev/null || echo 0)
  echo "[StaticAnalysis] Detected error nodes: ${COUNT}" | tee -a "${REPORT_TXT}"
fi

exit ${STATUS}
