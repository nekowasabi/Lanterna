# Lanterna verification map

This directory is the maintained source for verifying the user-facing behavior of Lanterna. Read the index before driving the app, then use the matching feature file as the recipe.

## Baseline preconditions

- Host is macOS 26 on Apple Silicon, with Xcode or the Command Line Tools, so `swift` can build `--triple arm64-apple-macosx26.0`.
- Run `bash .cursor/skills/verify-lanterna/scripts/doctor.sh` and require exit 0.
- Drive the suite with `bash scripts/test.sh` from the repo root. Do not launch a second menu-bar process while one started for a launch check is alive.
- A launch check, when the doctor passed, uses a fresh `LANTERNA_VERIFY_HOME` and the binary built in `Launch` of the skill.
- Never drive a process that was not started by this verification run. The suite does not attach to a user's running Lanterna.

## Driving conventions

- Start every recipe from the baseline unless its preconditions say otherwise.
- Treat every command as literal. Keep the `--filter` value unchanged.
- The harness is `bash scripts/test.sh`. It feeds the presenter keystrokes and reads the fake switcher and the fake surface.
- A step that names a test which does not exist fails. Do not replace it with a nearby test.
- Restore nothing in the user's config. The suite keeps its own fixtures.
- Do not remove proof artifacts during cleanup.

## Proof and skip reporting

- Capture the command, the exit code, and the test output.
- The observable end state is the one the feature file names (panel presented or not, `switchTo` count, which row was taken).
- Record the feature id with every artifact under `/opt/cursor/artifacts/lanterna-verify/`.
- Report an unreachable path with the attempted command and the unmet precondition. A missing macOS SDK is an unmet precondition.
- Do not report a skipped entry point as verified through a different path.

## Feature entry contract

Each feature file starts with an H1 title and one paragraph describing the user-visible behavior. It then uses exactly four H2 sections in this order.

1. `Sub-features` lists short IDs with one line for each behavior.
2. `How to get to it (user POV)` lists every user entry point.
3. `Driving it with scripts/test.sh` starts with `Preconditions:` and uses labeled bullets that pair each user action with an exact command and observable result.
4. `Gotchas` lists traps that can waste or invalidate a verification run.

## Features

- [Type to filter](./type-to-filter.md) covers opening the filter and narrowing the list.
- [Commit the highlighted row](./commit-selection.md) covers Return focusing the chosen window and closing the panel.
- [Dismiss the panel](./dismiss-panel.md) covers leaving without focusing a window.
- [Auto-focus a single candidate](./auto-focus-single-candidate.md) covers the filter narrowing to one row.
