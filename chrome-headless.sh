#!/bin/bash
# Start headless Chrome for Testing and wait until its CDP endpoint is up.
#
# browser-harness (CLI) and browser-harness-mcp connect to the running browser
# via BU_CDP_URL (default http://127.0.0.1:9222, set in the image). The Chrome
# sandbox does not work for a non-root user in most containers, hence
# --no-sandbox; the container itself is the isolation boundary.
#
# Idempotent: exits 0 immediately if Chrome is already listening.
# Override with CDP_PORT, CHROME_BIN, CHROME_PROFILE_DIR or CHROME_LOG.
set -euo pipefail

CDP_PORT="${CDP_PORT:-9222}"
CHROME_BIN="${CHROME_BIN:-/usr/local/bin/chrome}"
PROFILE_DIR="${CHROME_PROFILE_DIR:-${HOME}/.local/share/chrome-profile}"
LOG_FILE="${CHROME_LOG:-${HOME}/.local/share/chrome.log}"

if curl -sf "http://127.0.0.1:${CDP_PORT}/json/version" >/dev/null 2>&1; then
    echo "chrome already listening on 127.0.0.1:${CDP_PORT}"
    exit 0
fi

mkdir -p "${PROFILE_DIR}" "$(dirname "${LOG_FILE}")"

nohup "${CHROME_BIN}" \
    --headless=new \
    --no-sandbox \
    --disable-gpu \
    --disable-dev-shm-usage \
    --no-first-run \
    --remote-debugging-port="${CDP_PORT}" \
    --user-data-dir="${PROFILE_DIR}" \
    about:blank >>"${LOG_FILE}" 2>&1 &

for _ in $(seq 1 60); do
    if curl -sf "http://127.0.0.1:${CDP_PORT}/json/version" >/dev/null 2>&1; then
        echo "chrome listening on 127.0.0.1:${CDP_PORT}"
        echo "export BU_CDP_URL=http://127.0.0.1:${CDP_PORT}"
        exit 0
    fi
    sleep 0.5
done

echo "error: chrome did not expose CDP on 127.0.0.1:${CDP_PORT}; see ${LOG_FILE}" >&2
exit 1
