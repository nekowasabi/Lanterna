#!/usr/bin/env bash
# Tear down processes and scratch homes this verification run started.
# Proof under /opt/cursor/artifacts/lanterna-verify is left in place.
set -u

pidfile="/tmp/lanterna-verify-pids"
if [ -f "$pidfile" ]; then
  while read -r pid; do
    case "$pid" in
      ''|*[!0-9]*) continue ;;
    esac
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      echo "stopped pid=$pid"
    else
      echo "already gone pid=$pid"
    fi
  done < "$pidfile"
  rm -f "$pidfile"
fi

# Only homes this skill's launch notes. The glob is the scratch prefix.
found=0
for dir in /tmp/lanterna-verify-home-*; do
  if [ -d "$dir" ]; then
    rm -rf "$dir"
    echo "removed $dir"
    found=1
  fi
done
if [ "$found" -eq 0 ]; then
  echo "no scratch homes"
fi

echo "cleanup: evidence kept at /opt/cursor/artifacts/lanterna-verify"
exit 0
