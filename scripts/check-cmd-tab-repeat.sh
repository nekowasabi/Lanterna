#!/usr/bin/env bash
# SPEC.md runner for Cmd+Tab key repeat.
# Exit 0: every requested item passed.
# Exit 1: an item failed.
# Exit 2: an item could not run. Not a pass.
set -euo pipefail

cd "$(dirname "$0")/.."

item="${1:-all}"
source_file="Sources/Lanterna/Hotkey/InvocationKeyRepeat.swift"
harness="scripts/check-invocation-key-repeat.swift"
evidence_dir="${LANTERNA_VERIFY_EVIDENCE:-/tmp/lanterna-verify-evidence}/cmd-tab-key-repeat"
mkdir -p "$evidence_dir"
log="$evidence_dir/check-${item}.log"

pure_items=(KR-1 KR-2 KR-3 KR-4 KR-5 KR-6)

wants_pure=false
if [[ "$item" == "all" || "$item" == KR-* ]]; then
  wants_pure=true
fi

{
  echo "item=$item"
  echo "uname=$(uname -s)"
  echo "date=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} | tee "$log"

if [[ "$wants_pure" == true ]]; then
  if [[ ! -f "$source_file" || ! -f "$harness" ]]; then
    echo "FAIL $item missing $source_file or $harness" | tee -a "$log"
    exit 1
  fi
  if ! command -v swiftc >/dev/null 2>&1; then
    echo "BLOCKED $item swiftc is not installed, so the decision checks did not run" | tee -a "$log"
    if [[ "$item" == "all" ]]; then
      echo "BLOCKED KR-P this host is $(uname -s), not a Mac with the Lanterna toolchain" | tee -a "$log"
    fi
    exit 2
  fi
  out="$(mktemp -d)"
  filter=()
  if [[ "$item" != "all" ]]; then
    filter=("$item")
  fi
  if ! swiftc -o "$out/check-invocation-key-repeat" "$source_file" "$harness"; then
    echo "FAIL $item swiftc could not compile the decision checks" | tee -a "$log"
    exit 1
  fi
  set +e
  "$out/check-invocation-key-repeat" "${filter[@]}" | tee -a "$log"
  status="${PIPESTATUS[0]}"
  set -e
  rm -rf "$out"
  if [[ "$status" -ne 0 ]]; then
    echo "FAIL $item decision harness exit $status" | tee -a "$log"
    exit 1
  fi
fi

if [[ "$item" == "all" || "$item" == "KR-P" ]]; then
  if [[ "$(uname -s)" != "Darwin" ]] || ! command -v swift >/dev/null 2>&1; then
    echo "BLOCKED KR-P presenter tests need macOS and swift (uname=$(uname -s))" | tee -a "$log"
    if [[ "$item" == "KR-P" ]]; then
      exit 2
    fi
    echo "INCOMPLETE pure checks passed, presenter checks did not run" | tee -a "$log"
    exit 2
  fi
  set +e
  env -u SDKROOT -u DEVELOPER_DIR swift test --triple arm64-apple-macosx26.0 --filter 'InvocationKeyRepeatTests|PanelInvocationRepeatTests' | tee -a "$log"
  status="${PIPESTATUS[0]}"
  set -e
  if [[ "$status" -ne 0 ]]; then
    echo "FAIL KR-P swift test exit $status" | tee -a "$log"
    exit 1
  fi
  echo "PASS KR-P" | tee -a "$log"
fi

if [[ "$wants_pure" == false && "$item" != "KR-P" ]]; then
  echo "FAIL unknown item $item" | tee -a "$log"
  exit 1
fi

echo "PASS $item" | tee -a "$log"
exit 0
