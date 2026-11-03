#!/usr/bin/env bash
set -euo pipefail

# Real-world render-success benchmark: fetch a corpus of live public pages with
# inbrowse and report how many render to a usable document, plus latency + memory.
#
# Env:
#   INBROWSE_BIN  path to the inbrowse binary (default: inbrowse on PATH;
#                 OBSCURA_BIN is still honoured as a fallback)
# Needs outbound network. The live web drifts, so results are a snapshot.
# Extra args are forwarded to run.py (e.g. --wait 6, --sites my-list.txt).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export INBROWSE_BIN="${INBROWSE_BIN:-${OBSCURA_BIN:-inbrowse}}"
RESULTS_DIR="$SCRIPT_DIR/results"
mkdir -p "$RESULTS_DIR"

echo "[realworld] inbrowse: $INBROWSE_BIN"
python3 "$SCRIPT_DIR/realworld/run.py" "$@"

if [[ " $* " != *" --json "* ]]; then
  python3 "$SCRIPT_DIR/realworld/run.py" --json >"$RESULTS_DIR/realworld.json" 2>/dev/null || true
  echo "[realworld] json: $RESULTS_DIR/realworld.json"
fi
