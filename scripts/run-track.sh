#!/usr/bin/env bash
set -euo pipefail

# Run one benchmark track and keep its output under results/<date>-<track>/.
# Tracks run one at a time, on an otherwise idle host: a run during a build
# or another track gives wrong latency and memory numbers.
#
#   scripts/run-track.sh obstacle-course | stealth | compare | perf | realworld | reliability | wpt
#
# Env:
#   INBROWSE_BIN   the inbrowse binary (default: inbrowse on PATH)
#   CHROME_BIN     chrome for the compare track (default: google-chrome)
# Extra args are passed to the track's own runner.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACK="${1:?usage: run-track.sh <track> [args...]}"
shift

export INBROWSE_BIN="${INBROWSE_BIN:-inbrowse}"
OUT="$SCRIPT_DIR/results/$(date -u +%Y-%m-%d)-$TRACK"
mkdir -p "$OUT"

{
  echo "track:     $TRACK"
  echo "date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "inbrowse:  $("$INBROWSE_BIN" --version 2>&1 | head -1)"
  if [ "$TRACK" = compare ]; then
    echo "chrome:    $("${CHROME_BIN:-google-chrome}" --version 2>&1 | head -1)"
  fi
  echo "host:      $(uname -srm)"
  echo "cpus:      $(nproc)"
  echo "memory:    $(awk '/MemTotal/ {printf "%.1f GiB", $2/1048576}' /proc/meminfo 2>/dev/null || echo unknown)"
} | tee "$OUT/environment.txt"

case "$TRACK" in
  obstacle-course)
    # One measured pass, kept as JSON (the README tables are made from it).
    python3 "$SCRIPT_DIR/obstacle-course/run.py" --json "$@" >"$OUT/report.json"
    ;;
  stealth)
    python3 "$SCRIPT_DIR/stealth-bench/run.py" --json "$@" >"$OUT/report.json"
    ;;
  compare)
    RESULTS_DIR="$OUT" bash "$SCRIPT_DIR/scripts/run-compare.sh" "$@" | tee "$OUT/report.txt"
    ;;
  perf)
    bash "$SCRIPT_DIR/scripts/run-bench.sh" "$@" | tee "$OUT/report.txt"
    ;;
  realworld)
    python3 "$SCRIPT_DIR/realworld/run.py" --json "$@" >"$OUT/report.json"
    ;;
  reliability)
    python3 "$SCRIPT_DIR/reliability/sweep.py" "$@" | tee "$OUT/report.txt"
    ;;
  wpt)
    bash "$SCRIPT_DIR/scripts/run-wpt.sh" "$@" | tee "$OUT/report.txt"
    ;;
  *)
    echo "unknown track: $TRACK" >&2
    exit 2
    ;;
esac

echo "[run-track] $TRACK done; output in $OUT"
