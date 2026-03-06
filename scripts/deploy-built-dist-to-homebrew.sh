#!/usr/bin/env bash
set -euo pipefail

SRC_REPO="${1:-/Users/peter/DevProjects/openclaw}"
DST_ROOT="${2:-/opt/homebrew/lib/node_modules/openclaw}"

DIST_SRC="${SRC_REPO}/dist"
DIST_DST="${DST_ROOT}/dist"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="${DST_ROOT}/dist.backup-${TS}"

if [[ ! -d "${DIST_SRC}" ]]; then
  echo "ERROR: source dist not found: ${DIST_SRC}" >&2
  exit 1
fi

if [[ ! -d "${DIST_DST}" ]]; then
  echo "ERROR: target dist not found: ${DIST_DST}" >&2
  exit 1
fi

echo "==> Backup current dist"
cp -a "${DIST_DST}" "${BACKUP}"
echo "Backup created: ${BACKUP}"

echo "==> Sync built dist to Homebrew global package"
rsync -a --delete "${DIST_SRC}/" "${DIST_DST}/"

echo "==> Quick marker checks"
set +e
rg -n "function buildTimeSection\\(_params\\)|function buildRuntimeLine\\(|clipInboundContextText\\(|elideQueueText\\(item\\.prompt\\.replace" "${DIST_DST}"/*.js "${DIST_DST}"/plugin-sdk/*.js 2>/dev/null | sed -n '1,20p'
set -e

echo "==> Restart gateway"
openclaw gateway restart >/dev/null
openclaw gateway status | sed -n '1,40p'

echo
echo "Done."
echo "Rollback command:"
echo "  rm -rf \"${DIST_DST}\" && mv \"${BACKUP}\" \"${DIST_DST}\" && openclaw gateway restart"
