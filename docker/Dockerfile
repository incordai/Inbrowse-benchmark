# The benchmark environment: Ubuntu 22.04 with a released Inbrowse, Chrome for
# the head-to-head track, GNU time for peak memory, and Rust for the suite's
# own runners (wpt-runner, perf-bench, triage). Build it from the repository
# root, then run one track at a time on an otherwise idle host:
#
#   docker build -f docker/Dockerfile -t inbrowse-benchmark .
#   docker run --rm --cpus 2 -v "$PWD/results:/bench/results" inbrowse-benchmark \
#     bash scripts/run-track.sh obstacle-course
#
# Tracks: obstacle-course, stealth, compare, perf, realworld, reliability, wpt.
#
# INBROWSE_VERSION picks the release; its archive is checked against the
# release's SHA256SUMS before use.

FROM ubuntu:22.04

ARG INBROWSE_VERSION=0.3.0
ARG INBROWSE_VARIANT=inbrowse-x86_64-linux
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git python3 python3-venv time procps \
      build-essential pkg-config fonts-liberation \
 && rm -rf /var/lib/apt/lists/*

# Chrome, the baseline the head-to-head track compares against.
RUN curl -fsSL -o /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
 && apt-get update \
 && apt-get install -y --no-install-recommends /tmp/chrome.deb \
 && rm -f /tmp/chrome.deb \
 && rm -rf /var/lib/apt/lists/*

# Rust for the suite's own crates.
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal
ENV PATH=/root/.cargo/bin:$PATH

# The Inbrowse release under test, verified against its SHA256SUMS.
RUN set -eu; cd /tmp; \
    base="https://github.com/incordai/Inbrowse/releases/download/v${INBROWSE_VERSION}"; \
    curl -fsSLO "$base/${INBROWSE_VARIANT}.tar.gz"; \
    curl -fsSLO "$base/SHA256SUMS"; \
    grep " ${INBROWSE_VARIANT}.tar.gz\$" SHA256SUMS | sha256sum -c -; \
    mkdir -p /opt/inbrowse; \
    tar -xzf "${INBROWSE_VARIANT}.tar.gz" -C /opt/inbrowse; \
    rm -f "${INBROWSE_VARIANT}.tar.gz" SHA256SUMS; \
    /opt/inbrowse/inbrowse --version

ENV INBROWSE_BIN=/opt/inbrowse/inbrowse \
    CHROME_BIN=/usr/bin/google-chrome \
    INBROWSE_VERSION=${INBROWSE_VERSION}

WORKDIR /bench
COPY . /bench
RUN cargo build --release --locked -j 2

CMD ["bash", "scripts/run-track.sh", "obstacle-course"]
