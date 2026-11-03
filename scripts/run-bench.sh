#!/usr/bin/env bash
set -euo pipefail

# Run the Inbrowse perf benchmark against a small default URL list and write the
# JSON to results/perf.json. The human-readable table is printed too. Pass extra
# URLs or flags as args and they are forwarded to perf-bench.
#
# Env:
#   INBROWSE_BIN   path to the inbrowse binary (default: inbrowse on PATH;
#                  OBSCURA_BIN is still honoured as a fallback)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

INBROWSE_BIN="${INBROWSE_BIN:-${OBSCURA_BIN:-inbrowse}}"
RESULTS_DIR="$SCRIPT_DIR/results"
PERF_JSON="$RESULTS_DIR/perf.json"

DEFAULT_URLS=(
  "https://example.com"
  "https://www.iana.org/help/example-domains"
)

mkdir -p "$RESULTS_DIR"

echo "[run-bench] building perf-bench"
( cd "$SCRIPT_DIR" && cargo build --release -p perf-bench )

BENCH="$SCRIPT_DIR/target/release/perf-bench"

# If the caller passed args, use those. Otherwise fall back to the default list.
if [ "$#" -gt 0 ]; then
  ARGS=("$@")
else
  ARGS=("${DEFAULT_URLS[@]}")
fi

export INBROWSE_BIN

# perf-bench takes the binary as --binary; pass INBROWSE_BIN unless the caller
# already gave --binary (clap rejects a repeated --binary).
case " ${ARGS[*]} " in
  *" --binary "*|*" --binary="*) ;;
  *) ARGS=(--binary "$INBROWSE_BIN" "${ARGS[@]}") ;;
esac

echo "[run-bench] running perf-bench"
# Human table to the terminal.
"$BENCH" "${ARGS[@]}"

echo "[run-bench] writing JSON results"
# JSON to disk for tracking over time.
"$BENCH" --json "${ARGS[@]}" >"$PERF_JSON"

echo ""
echo "[run-bench] done."
echo "[run-bench] perf json: $PERF_JSON"
