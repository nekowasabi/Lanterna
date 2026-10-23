---
name: verify-lanterna
description: Drive Lanterna, the macOS list-style window switcher, through its Swift harness when proving Cmd+Tab key repeat, release-to-switch, filtering, or the parallel switcher. Use when a change needs a scripted user-path check and the GUI cannot be launched.
disable-model-invocation: true
---

# Verify Lanterna

Lanterna is a menu-bar macOS app. The user holds Command and presses Tab to walk a window list, then releases Command to switch. This skill drives that behavior through the repo's Swift checks. It does not click the panel. There is no debug port, no Playwright harness, and no CLI that opens the switcher.

On Linux the app cannot launch. Doctor says so. Do not treat a doctor pass as a launch. Do not claim a real Mac keyboard was observed unless the presenter tests in KR-P actually ran on Darwin.

## Launch

From the repo root, on a Mac with Nix, Xcode or the Command Line Tools, and the Apple Silicon SDK:

```bash
bash scripts/generate-version.sh --dev
nix develop --command swift build --triple arm64-apple-macosx26.0 -Xswiftc -warnings-as-errors
```

Ready means `swift build` exits 0 and `.build/debug/Lanterna` exists. The process is a menu-bar app with no window until a hotkey. Launching it registers Cmd+Tab and takes that shortcut from the system until the process quits. Only launch it in a disposable macOS session.

```bash
./.build/debug/Lanterna
```

There is no ready log line that means the panel is up. The process staying alive after the hotkey registration line is as far as launch goes. Quit with the menu item or `kill` on the pid you started. Never `killall Lanterna`.

On Linux, skip the build. Record `uname` and the missing toolchain in the evidence directory. That host will not grow a usable panel.

Teardown is `bash scripts/verify-lanterna-cleanup.sh`. It does not delete evidence.

## Doctor

Run this before a drive, and again whenever a command fails for an environmental reason.

```bash
bash scripts/verify-lanterna-doctor.sh
```

Exit 0 means the checkout is the Lanterna tree and `origin` is `nekowasabi/Lanterna`. It also prints whether `swiftc` and `swift` exist and whether the host is Darwin. A non-Darwin line means the GUI drive is refused. Continue with the repeat harness only.

## Drive

The harness is `bash scripts/check-cmd-tab-repeat.sh`. It compiles `Sources/Lanterna/Hotkey/InvocationKeyRepeat.swift` with `scripts/check-invocation-key-repeat.swift` and runs SPEC.md items KR-1 through KR-6. On Darwin, with `swift` installed, an `all` run also executes `InvocationKeyRepeatTests` and `PanelInvocationRepeatTests`.

```bash
mkdir -p /tmp/lanterna-verify-evidence/cmd-tab-key-repeat
LANTERNA_VERIFY_EVIDENCE=/tmp/lanterna-verify-evidence bash scripts/check-cmd-tab-repeat.sh | tee /tmp/lanterna-verify-evidence/cmd-tab-key-repeat/drive.log
```

One feature is enough for a first proof. Drive [Cmd+Tab key repeat](features/cmd-tab-key-repeat.md). The other feature files are the map for later runs. A path the map lists and this command does not exercise is not verified.

Exit codes:

- 0, every requested item passed, including KR-P on a Mac.
- 1, an item failed. Do not weaken the item.
- 2, the host could not run an item. Say which item, and do not call it a pass.

The pure checks decide arming, direction, and timing. They do not open a panel. KR-P is the check that reads the chosen row after an injected repeat sleep. If KR-P is blocked, the selection walk is unverified.

## Evidence

Write under `/tmp/lanterna-verify-evidence/cmd-tab-key-repeat/`. Keep the command, the log, and the exit code. The check script also writes `check-<item>.log` there.

A proof of the repeat decision is the harness printing `PASS KR-1` through `PASS KR-6` and exiting 0. A proof of the panel walk is `PASS KR-P` from `swift test` on Darwin. A screenshot of a source file is not evidence. A mock of `handleHotkey` that never runs the presenter is not evidence.

The app has no dry-run switch. Building it on macOS does not register hotkeys. Running the binary does. Do not infer safety from the binary's name.

## Cleanup

```bash
bash scripts/verify-lanterna-cleanup.sh
```

That script kills a pid recorded in `driver.pid` if a drive started one, and deletes `/tmp/lanterna-verify-swiftc`. It leaves `/tmp/lanterna-verify-evidence`. After cleanup, `test -f /tmp/lanterna-verify-evidence/cmd-tab-key-repeat/drive.log` must still succeed when a drive wrote that log.

Do not kill by process name.

## Helpers

- `bash scripts/verify-lanterna-doctor.sh` prints the host and the remote. Exit 0 is a tree worth driving.
- `bash scripts/check-cmd-tab-repeat.sh [KR-1|KR-2|KR-3|KR-4|KR-5|KR-6|KR-P|all]` runs the acceptance items. Default is `all`.
- `bash scripts/verify-lanterna-cleanup.sh` removes scratch state and keeps evidence.

## Maintenance

When the switcher's keys or the repeat decision change, update the feature map with `/maintain-verification-skill` so the recipes stay the ones a user can still perform.
