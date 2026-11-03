#!/usr/bin/env bash
set -euo pipefail

# Run the Inbrowse obstacle course: modern-web capability + speed fixtures.
# Boots a local HTTP origin (in run.py), drives `inbrowse fetch` against each
# fixture, and reports per-stage correctness + latency.
#
# Env:
#   INBROWSE_BIN  path to the inbrowse binary (default: inbrowse on PATH)
# Extra args are forwarded to run.py (e.g. --json, --runs 10, --filter react).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export INBROWSE_BIN="${INBROWSE_BIN:-inbrowse}"

RESULTS_DIR="$SCRIPT_DIR/results"
mkdir -p "$RESULTS_DIR"

echo "[obstacle-course] inbrowse bin: $INBROWSE_BIN"
python3 "$SCRIPT_DIR/obstacle-course/run.py" "$@"

# Also write a JSON snapshot for tracking over time (unless caller asked for JSON
# on stdout already).
if [[ " $* " != *" --json "* ]]; then
  python3 "$SCRIPT_DIR/obstacle-course/run.py" --json >"$RESULTS_DIR/obstacle-course.json" 2>/dev/null || true
  echo "[obstacle-course] json: $RESULTS_DIR/obstacle-course.json"
fi
