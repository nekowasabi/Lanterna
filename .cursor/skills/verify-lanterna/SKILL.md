---
name: verify-lanterna
description: "Drive Lanterna, the macOS list-style window switcher, through its Swift Testing harness and record proof. Use when a change to filtering, committing, dismissing, or auto-focusing a single candidate needs evidence, or when checking whether this machine can launch the app."
---

# Verify Lanterna

Lanterna is a menu-bar window switcher for macOS 26 on Apple Silicon. The user shows the panel with a hotkey, types to narrow the list, and confirms a row to focus that window. There is no web UI and no command-line switcher. The scripted drive path in this repo is the Swift Testing suite, which feeds `PanelPresenter` the same keystrokes the hotkey path feeds. A real menu-bar session needs a Mac and is not something this skill starts twice.

## Launch

From the repo root, on macOS 26 arm64 with Xcode or the Command Line Tools:

```bash
bash scripts/generate-version.sh --dev
swift build --triple arm64-apple-macosx26.0
```

Ready means `.build/debug/Lanterna` exists, `lipo -archs .build/debug/Lanterna` prints `arm64`, and the built binary stays running when started with a disposable config directory:

```bash
mkdir -p "$LANTERNA_VERIFY_HOME/Library/Application Support/Lanterna"
HOME="$LANTERNA_VERIFY_HOME" .build/debug/Lanterna
```

Set `LANTERNA_VERIFY_HOME` to an empty directory created for this run, for example `/tmp/lanterna-verify-home-$RUN_ID`. The process is ready when it is still alive after one second and has not printed `config invalid`. There is no port. A second launch shares the hotkey tap and the menu-bar extra, so this skill refuses to start a second process while the one it started is alive.

Teardown is `Cleanup` below. On Linux, or anywhere `swift` and the macOS SDK are missing, do not treat a failed build as a product failure. Record the command and the error in the evidence directory and stop the launch. The unit-test drive still needs the same SDK, so it stops at the same point.

## Doctor

Run this first whenever a drive looks wrong:

```bash
bash .cursor/skills/verify-lanterna/scripts/doctor.sh
```

Exit 0 means this host is Darwin, `swift` is on `PATH` or at `/usr/bin/swift`, and the repo root contains `Package.swift` and `scripts/test.sh`. Exit 1 means the instance is not worth driving. The script prints `os`, `arch`, and the reason. It does not build, launch, or edit the tree.

## Drive

The harness is `bash scripts/test.sh`, which is `swift test --triple arm64-apple-macosx26.0` with the repo's warning and Testing-framework flags. It drives `PanelPresenter.handleHotkey` and `handleKeyStroke` and reads `FakeWindowSwitcher.targets` and `FakeSurface.isPresented`. That is the production input path with the window server replaced. It is not a test-only setter that flips the focused app.

Preconditions for every recipe:

- `bash .cursor/skills/verify-lanterna/scripts/doctor.sh` exited 0.
- The work tree is this repo.
- No Lanterna process started by this skill is still running. The tests do not need one.

Run a recipe's command from the repo root. A filter is a Swift Testing name, for example:

```bash
bash scripts/test.sh --filter FilterActivationTests/invokingOnAClosedPanelShowsTheWholeList
```

Pass means the command exits 0. The feature files name the filter and the observable result for each step. Do not substitute a different test and call the step verified.

The acceptance contract for auto-focus is `SPEC.md`. Run it with:

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh
```

## Evidence

Write proof under `/opt/cursor/artifacts/lanterna-verify/`. Cleanup must not delete that directory.

For a drive, record the feature id, the exact command, the exit code, and stdout plus stderr. A passing test is evidence that the presenter took the keystrokes and that the fake switcher and surface ended in the state the feature file names. A screenshot is not available from this harness. Do not claim a real Mac focused a window unless the binary was launched on macOS and that session was observed.

For a launch that cannot start, record the doctor output and the build or launch error in the same directory. That file is evidence of a blocked run, not of a passing feature.

Mocks stay where the suite already isolates the window server (`FakeWindowSwitcher`, `FakeSurface`). Do not add a network stub. The tests do not open a browser.

## Cleanup

```bash
bash .cursor/skills/verify-lanterna/scripts/cleanup.sh
```

The script reads `/tmp/lanterna-verify-pids` and terminates only those pids. It removes `/tmp/lanterna-verify-home-*` directories created as scratch homes. It does not delete `/opt/cursor/artifacts/lanterna-verify/`. It does not kill by process name.

## Helpers

- `bash .cursor/skills/verify-lanterna/scripts/doctor.sh` answers whether this host can drive the suite.
- `bash .cursor/skills/verify-lanterna/scripts/check-spec.sh [AF-N]` runs the acceptance items in `SPEC.md`.
- `bash .cursor/skills/verify-lanterna/scripts/cleanup.sh` tears down processes and scratch homes this skill started.

After a change to filtering or committing, re-read the feature map and use `/maintain-verification-skill` when a user-facing path in the map no longer matches the app.
