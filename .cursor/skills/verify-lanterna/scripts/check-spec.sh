#!/usr/bin/env bash
# Run SPEC.md acceptance items. One ID argument limits the run to that item.
# Prints "ID PASS" or "ID FAIL" and exits 0 only when every selected item passes.
set -u

root="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$root"

want="${1:-all}"
fail=0

pass() { echo "$1 PASS"; }
fail_item() {
  echo "$1 FAIL $2"
  fail=1
}

need_swift() {
  local id="$1"
  local filter="$2"
  if [ "$(uname -s)" != "Darwin" ]; then
    fail_item "$id" "environment: host is $(uname -s) $(uname -m), not macOS arm64. Refusing to claim swift test --filter $filter passed."
    return 1
  fi
  if ! command -v swift >/dev/null 2>&1 && [ ! -x /usr/bin/swift ]; then
    fail_item "$id" "environment: swift is missing. Refusing to claim swift test --filter $filter passed."
    return 1
  fi
  local log
  log="$(mktemp)"
  if bash scripts/test.sh --filter "$filter" >"$log" 2>&1; then
    pass "$id"
    rm -f "$log"
    return 0
  fi
  local code=$?
  fail_item "$id" "swift test --filter $filter exited $code. Tail: $(tail -n 20 "$log" | tr '\n' ' ')"
  rm -f "$log"
  return 1
}

have() {
  local file="$1"
  local text="$2"
  grep -F -q -- "$text" "$file"
}

af1() { need_swift AF-1 'AutoFocusSingleCandidateTests/typingDownToOneCandidateActivatesIt'; }
af2() { need_swift AF-2 'AutoFocusSingleCandidateTests/aBurstThatWidensAgainDoesNotActivate'; }
af3() { need_swift AF-3 'AutoFocusSingleCandidateTests/anAlreadySingleListDoesNotActivate'; }
af4() { need_swift AF-4 'AutoFocusSingleCandidateTests/typingThatKeepsTheOnlyRowDoesNotActivate'; }
af5() { need_swift AF-5 'AutoFocusSingleCandidateTests/anEmptyQueryDoesNotActivate'; }
af6() { need_swift AF-6 'AutoFocusSingleCandidateTests/clearingBeforeTheWaitDoesNotActivate'; }
af7() { need_swift AF-7 'AutoFocusSingleCandidateTests/theSettingOffDoesNotActivate'; }
af8() { need_swift AF-8 'AutoFocusSingleCandidateTests/activatingTwiceDoesNotSwitchTwice'; }
af9() { need_swift AF-9 'AutoFocusSingleCandidateTests/recoveringFromNoMatchDoesNotActivate'; }
af10() {
  need_swift AF-10 'AutoFocusSingleCandidateTests/absentConfigMeansOn|AutoFocusSingleCandidateTests/falseConfigRoundTrips'
}

af11() {
  local missing=""
  have Sources/Lanterna/UI/SingleCandidateFocus.swift 'Duration.milliseconds(180)' || missing="$missing settle"
  have Sources/Lanterna/Support/AppConfiguration.swift 'autoFocusSingleCandidate' || missing="$missing knownKeys"
  have config/ConfigSchema.pkl 'autoFocusSingleCandidate' || missing="$missing ConfigSchema.pkl"
  have config/GenJsonSchema.pkl 'autoFocusSingleCandidate' || missing="$missing GenJsonSchema.pkl"
  have config/config-schema.json 'autoFocusSingleCandidate' || missing="$missing config-schema.json"
  have Sources/Lanterna/Model/SettingsValues.swift 'autoFocusSingleCandidate: true' || missing="$missing default"
  have docs/src/content/docs/en/usage.mdx 'autoFocusSingleCandidate' || missing="$missing en usage"
  have docs/src/content/docs/ja/usage.mdx 'autoFocusSingleCandidate' || missing="$missing ja usage"
  have Sources/Lanterna/UI/SettingsAppearanceView.swift 'Auto-focus single match' || missing="$missing toggle"
  if [ -z "$missing" ]; then
    pass AF-11
  else
    fail_item AF-11 "missing:$missing"
  fi
}

run_one() {
  case "$1" in
    AF-1) af1 ;;
    AF-2) af2 ;;
    AF-3) af3 ;;
    AF-4) af4 ;;
    AF-5) af5 ;;
    AF-6) af6 ;;
    AF-7) af7 ;;
    AF-8) af8 ;;
    AF-9) af9 ;;
    AF-10) af10 ;;
    AF-11) af11 ;;
    *)
      echo "unknown item $1" >&2
      exit 2
      ;;
  esac
}

if [ "$want" = "all" ]; then
  for id in AF-1 AF-2 AF-3 AF-4 AF-5 AF-6 AF-7 AF-8 AF-9 AF-10 AF-11; do
    run_one "$id"
  done
else
  run_one "$want"
fi

exit "$fail"
