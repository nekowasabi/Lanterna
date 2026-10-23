#!/usr/bin/env bash
# Removes processes and scratch builds this verification run started.
# Leaves /tmp/lanterna-verify-evidence alone.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f /tmp/lanterna-verify-evidence/cmd-tab-key-repeat/driver.pid ]]; then
  pid="$(cat /tmp/lanterna-verify-evidence/cmd-tab-key-repeat/driver.pid)"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" || true
    echo "cleanup killed pid $pid"
  fi
  rm -f /tmp/lanterna-verify-evidence/cmd-tab-key-repeat/driver.pid
fi

rm -rf /tmp/lanterna-verify-swiftc
echo "cleanup scratch removed"
echo "cleanup evidence kept at /tmp/lanterna-verify-evidence"
exit 0
