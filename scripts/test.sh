#!/usr/bin/env bash
# Runs the test suite with the host Apple toolchain.
#
# SDKROOT and DEVELOPER_DIR are cleared unconditionally: Nix's devshell exports
# them pointing at an old Apple SDK that has no SwiftPM. A DEVELOPER_DIR set on
# purpose is discarded here too, so /usr/bin/swift always picks the toolchain it
# would use with no environment at all.
#
# The triple is pinned; CONTRIBUTING.md says why.
#
# The extra flags are added only when the active developer directory is the
# Command Line Tools and it holds Testing.framework: CLT ships Swift Testing
# outside the toolchain's default search paths, and DYLD_* variables are
# stripped from the SIP-protected test helper, so the framework and its interop
# dylib have to be baked in as rpaths at link time. With Xcode selected, its
# compiler already finds its own Swift Testing; pointing it at the CLT copy
# pairs a newer @Test macro with an older framework and the suite fails to
# compile.
set -euo pipefail

cd "$(dirname "$0")/.."

# Stamp first so the build names the checkout at hand; a no-op when the stamp
# is already current (see generate-version.sh).
bash scripts/generate-version.sh --dev >/dev/null

CLT=/Library/Developer/CommandLineTools
CLT_FRAMEWORKS=$CLT/Library/Developer/Frameworks
CLT_LIB=$CLT/Library/Developer/usr/lib

flags=()
if [ "$(env -u DEVELOPER_DIR /usr/bin/xcode-select -p 2>/dev/null)" = "$CLT" ] \
    && [ -d "$CLT_FRAMEWORKS/Testing.framework" ]; then
    flags=(
        -Xswiftc -F"$CLT_FRAMEWORKS"
        -Xlinker -F"$CLT_FRAMEWORKS"
        -Xlinker -rpath -Xlinker "$CLT_FRAMEWORKS"
        -Xlinker -rpath -Xlinker "$CLT_LIB"
    )
fi

# `"${flags[@]}"` alone aborts under `set -u` in bash 3.2, which macOS ships as
# /bin/bash and which this script may run under, when the array is empty.
# Swift warnings fail locally too; CMigemo stays silent via -w in Package.swift.
exec env -u SDKROOT -u DEVELOPER_DIR /usr/bin/swift test \
    --triple arm64-apple-macosx26.0 ${flags[@]+"${flags[@]}"} -Xswiftc -warnings-as-errors "$@"
