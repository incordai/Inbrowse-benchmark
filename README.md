# inbrowse-benchmark

inbrowse-benchmark: conformance, capability and performance benchmarks for
[Inbrowse](https://github.com/incordai/Inbrowse), a headless browser engine
written in Rust for web scraping and AI agent automation. WPT coverage here is
intentionally limited to the classic DOM/JavaScript standards path. Rendering
regressions belong to Inbrowse's deterministic `render-repros/` suite in the main
repository, where changes can be reviewed against engine-owned expectations.

This suite is derived from [obscura-benchmark](https://github.com/h4ckf0r0day/obscura-benchmark); see `NOTICE`.

## Benchmark tracks

| track | question it answers | where |
| ----- | ------------------- | ----- |
| WPT conformance | how much of the web platform does Inbrowse implement correctly | `crates/wpt-runner`, `crates/triage` |
| Obstacle course | does it handle the modern web (React/SPA/async/web APIs), and how fast | `obstacle-course/` |
| vs headless Chrome | how does its speed and memory compare to the standard headless engine | `compare/` |
| Real-world corpus | does it render real public pages, including SPAs | `realworld/` |
| Stealth bench | does it present a consistent, undetectable Chrome fingerprint | `stealth-bench/` |
| Perf bench | per-page `fetch` / `scrape` latency on a small URL set | `crates/perf-bench` |
| Reliability | does it crash, panic, or hang on a large corpus of real pages | `reliability/` |

## Results

Results: published under `results/published/` after each full run.

## Choosing the binary

Every harness takes the Inbrowse binary from `INBROWSE_BIN` (on Windows, point
it at `inbrowse.exe`). When `INBROWSE_BIN` is unset, the Python runners and the
`scripts/` wrappers use `inbrowse` on `PATH`.
`inbrowse scrape` (used by the perf bench's `--scrape` mode) also needs
`inbrowse-worker` (`inbrowse-worker.exe`) next to the main binary.

## 1. WPT conformance

`crates/wpt-runner` runs every supported WPT testharness file through a separate
`inbrowse fetch` process and reads the result left by
`wpt-overlay/resources/testharnessreport.js`. WPT reftests are not run here:
rendering regression ownership stays with the deterministic fixtures in the
main Inbrowse repository.

Tests requiring unimplemented runner automation (testdriver, PAC, or HTTP/3
serving) are reported as unsupported, not as engine
failures. `crates/triage` reports that count separately and groups real failures
into deduplicated root causes.

```sh
# one-time setup: check out the revision in wpt-config/WPT_COMMIT,
# install the report overlay, and build the manifest
scripts/setup-wpt.sh
# then add the WPT hostnames once (needs sudo), as printed by setup-wpt.sh:
#   ( cd wpt && ./wpt make-hosts-file ) | sudo tee -a /etc/hosts

# full classic WPT pass
INBROWSE_BIN=/path/to/inbrowse-no-render \
  scripts/run-wpt.sh --concurrency 32 --wait-secs 15

# a subset, by one path substring
INBROWSE_BIN=/path/to/inbrowse-no-render \
  scripts/run-wpt.sh FileAPI/url/
```

The suite is roughly 38k test variants at the current pin. Use a concurrency
that does not oversubscribe the host: oversubscription makes per-test timeouts
fire and depresses the pass rate. Outputs are written under `results/`, including
the JSON report and a triage Markdown report. Report WPT as subtest pass rate,
not whole-file pass rate. Subtest pass rate is reported per tier; a tier is a
capability scope defined in `crates/triage/src/tiers.list`, not a cherry-picked
subset.

Build the classic Inbrowse binary without optional features:

```sh
BENCH_BIN_DIR=/path/to/inbrowse-benchmark/.bench-bin
mkdir -p "$BENCH_BIN_DIR"
CARGO_INCREMENTAL=0 CARGO_BUILD_JOBS=2 cargo build --release \
  -p inbrowse-cli --bins --no-default-features
cp target/release/inbrowse "$BENCH_BIN_DIR/inbrowse-no-render"
```

Run those build commands in the Inbrowse repository. Record its exact commit with
the result commit; the WPT side is reproducibly pinned by this repository.

## 2. Obstacle course

A curated set of small self-contained modern-web pages that a no-DOM-engine
browser cannot handle. Each fixture runs its JavaScript and asserts a
deterministic result; the runner also times each page. See
`obstacle-course/README.md` for the full stage list.

```sh
INBROWSE_BIN=/path/to/inbrowse scripts/run-obstacle-course.sh
INBROWSE_BIN=/path/to/inbrowse scripts/run-obstacle-course.sh --filter react --runs 10
```

It exits non-zero if any stage's result does not match, so it doubles as a
correctness regression check.

## 3. Head-to-head vs Chrome

`compare/` runs Inbrowse and headless Chrome as cold processes over the same
pages and reports latency, peak memory, and throughput under concurrency. See
`compare/README.md`.

```sh
INBROWSE_BIN=/path/to/inbrowse CHROME_BIN=google-chrome scripts/run-compare.sh
```

Run it on an idle host; CPU contention skews throughput (memory is unaffected).

## 4. Real-world corpus

`realworld/` fetches a list of live public pages and reports render-success rate,
latency, and memory. See `realworld/README.md`.

```sh
INBROWSE_BIN=/path/to/inbrowse scripts/run-realworld.sh
```

## 5. Stealth bench

`stealth-bench/` evaluates Inbrowse's browser fingerprint, anti-detection measures,
and cross-page consistency when running in `--stealth` mode. It runs locally
and does not require external network access.

```sh
INBROWSE_BIN=/path/to/inbrowse-stealth python3 stealth-bench/run.py --stealth
```

Build the stealth binary in the Inbrowse repository with
`--features render,stealth`; a binary built without the `stealth` feature does
not exercise the stealth transport.

## 6. Perf bench

`crates/perf-bench` times `inbrowse fetch` / `inbrowse scrape` on a small default
URL set (override by passing URLs).

```sh
INBROWSE_BIN=/path/to/inbrowse scripts/run-bench.sh
INBROWSE_BIN=/path/to/inbrowse scripts/run-bench.sh https://example.com https://news.ycombinator.com
```

## 7. Reliability

`reliability/sweep.py` renders a large corpus (a one-level crawl from the
real-world seed list) and classifies each outcome from the exit code and stderr
as rendered, thin, hang, crash, or panic.

```sh
INBROWSE_BIN=/path/to/inbrowse python3 reliability/sweep.py
```

## Repo layout

```
crates/
  wpt-runner/      classic WPT testharness runner
  triage/          groups WPT failures into root causes; tiers.list defines the tiers
  perf-bench/      times `inbrowse fetch` / `inbrowse scrape`
obstacle-course/   modern-web capability + speed fixtures (+ run.py, manifest.json)
compare/           inbrowse vs headless Chrome: head-to-head.py, scale.py
realworld/         live-page render-success corpus: sites.txt, run.py
reliability/       crash / hang / panic sweep: sweep.py
stealth-bench/     stealth fingerprint, anti-detection, and consistency test suite
wpt-overlay/       the custom WPT report script installed into the WPT checkout
scripts/           setup and run wrappers
results/           generated run artifacts (gitignored except results/published/)
wpt/               the WPT checkout (gitignored; created by setup-wpt.sh)
```

## Setup and requirements

- Rust toolchain (`cargo build --release` builds the runner, triage, and perf-bench).
- An Inbrowse binary, passed via `INBROWSE_BIN`.
- Python 3 for the obstacle-course, compare, and realworld runners.
  `compare/scale.py` uses `psutil` for memory sampling (`pip install psutil`),
  and the compare/realworld harnesses read peak RSS from GNU `time -v`.
- For the head-to-head, a Chrome or Chromium build (`CHROME_BIN`).
- For WPT, the one-time `scripts/setup-wpt.sh` (checks out the pinned WPT commit,
  builds the manifest, and installs the report overlay) plus the WPT hostnames
  in `/etc/hosts`.

`results/` and the `wpt/` checkout are gitignored; run artifacts are regenerated
by the scripts. Reviewed baselines go under `results/published/`.

## License

Apache License 2.0; see `LICENSE` and `NOTICE`.
