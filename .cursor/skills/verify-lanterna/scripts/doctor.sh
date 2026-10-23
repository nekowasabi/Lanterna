#!/usr/bin/env bash
# Read-only check: is this host worth driving Lanterna on?
set -u

root="$(cd "$(dirname "$0")/../../../.." && pwd)"
echo "os=$(uname -s)"
echo "arch=$(uname -m)"
echo "root=$root"

fail() {
  echo "doctor: not worth driving. $1"
  exit 1
}

if [ "$(uname -s)" != "Darwin" ]; then
  fail "Lanterna is a macOS 26 arm64 app and this host is $(uname -s) $(uname -m)."
fi

if [ "$(uname -m)" != "arm64" ]; then
  fail "the build triple is arm64-apple-macosx26.0 and this host is $(uname -m)."
fi

swift_bin=""
if command -v swift >/dev/null 2>&1; then
  swift_bin="$(command -v swift)"
elif [ -x /usr/bin/swift ]; then
  swift_bin="/usr/bin/swift"
else
  fail "swift is not on PATH and /usr/bin/swift is missing."
fi
echo "swift=$swift_bin"

if [ ! -f "$root/Package.swift" ] || [ ! -f "$root/scripts/test.sh" ]; then
  fail "Package.swift or scripts/test.sh is missing under $root."
fi

echo "doctor: worth driving"
exit 0
