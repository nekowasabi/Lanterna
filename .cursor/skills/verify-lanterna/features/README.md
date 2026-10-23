# Lanterna verification map

This directory is the maintained source for verifying Lanterna's user-facing behavior. Read the index, then use the matching feature file.

## Baseline preconditions

- The checkout is `nekowasabi/Lanterna` and `bash scripts/verify-lanterna-doctor.sh` exits 0.
- The repeat harness is `bash scripts/check-cmd-tab-repeat.sh`.
- On macOS the presenter suite is `swift test --triple arm64-apple-macosx26.0 --filter PanelInvocationRepeatTests`.
- Do not launch `Lanterna.app` on a machine whose Cmd+Tab must keep working. Launch steals that hotkey until the process quits.
- Linux cannot show the panel. A blocked KR-P item stays blocked.

## Driving conventions

- Start from the feature's preconditions.
- Treat commands as literal.
- Prefer the Swift harness over a description of a click.
- The panel has no accessibility id in this harness. The observable stand-in for the chosen row is the presenter test's selection id.

## Proof and skip reporting

- Capture the command, the log, and the exit code under `/tmp/lanterna-verify-evidence/cmd-tab-key-repeat/`.
- A pure PASS line proves the decision. It does not prove the panel moved.
- KR-P proves the chosen row changed after the injected repeat sleep.
- Report a blocked item with the command and the unmet precondition. Do not mark it verified through a different path.

## Feature entry contract

Each feature file has an H1, one paragraph, and four H2 sections in order: `Sub-features`, `How to get to it (user POV)`, `Driving it with the Lanterna harness`, `Gotchas`.

## Features

- [Cmd+Tab key repeat](./cmd-tab-key-repeat.md) covers holding Tab, releasing it, and Shift+Cmd+Tab.
- [Release to switch](./release-to-switch.md) covers letting go of Command to commit the chosen row.
- [Filter](./filter.md) covers Cmd+Space and typing to narrow the list.
- [Parallel switcher](./parallel-switcher.md) covers Opt+Tab.
