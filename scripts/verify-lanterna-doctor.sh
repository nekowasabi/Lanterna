#!/usr/bin/env bash
# Read-only check from .cursor/skills/verify-lanterna. Exit 0 means the
# instance is worth driving the harness. It does not mean the Mac app launched.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "doctor uname=$(uname -s) $(uname -m)"
echo "doctor pwd=$(pwd)"
echo "doctor branch=$(git rev-parse --abbrev-ref HEAD)"
echo "doctor head=$(git rev-parse --short HEAD)"

origin="$(git remote get-url origin)"
case "$origin" in
  *nekowasabi/Lanterna*)
    echo "doctor origin=nekowasabi/Lanterna"
    ;;
  *)
    echo "doctor FAIL origin is not nekowasabi/Lanterna"
    exit 1
    ;;
esac

if [[ -f Package.swift && -d Sources/Lanterna/Hotkey && -d Tests/LanternaTests ]]; then
  echo "doctor tree=lanterna sources present"
else
  echo "doctor FAIL package tree is incomplete"
  exit 1
fi

if command -v swiftc >/dev/null 2>&1; then
  echo "doctor swiftc=$(command -v swiftc)"
else
  echo "doctor swiftc=absent"
fi

if command -v swift >/dev/null 2>&1; then
  echo "doctor swift=$(command -v swift)"
else
  echo "doctor swift=absent"
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "doctor surface=macOS toolchain may build the app"
else
  echo "doctor surface=not macOS. The app cannot launch here. Drive the repeat harness, not the GUI."
fi

echo "doctor ok"
exit 0
