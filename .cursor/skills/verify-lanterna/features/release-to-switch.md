# Release to switch

With the switcher open, releasing Command switches to the highlighted window. The list stays up while Command stays down.

## Sub-features

- `release-commit` activates the chosen window when Command goes up.
- `release-during-delay` can switch without showing the panel when a show delay is set.
- `second-press-fallback` closes on a second Cmd+Tab when Input Monitoring never started.

## How to get to it (user POV)

- Hold Command, press Tab, release Command.
- Hold Command, press Tab, wait out a show delay, release Command.
- Press Cmd+Tab twice when the modifier monitor is not running.

## Driving it with the Lanterna harness

Preconditions:

- Doctor exits 0.
- macOS with `swift` on `PATH` for the presenter suite. Linux does not run these tests.

- **Release commits.** Run `swift test --triple arm64-apple-macosx26.0 --filter PanelPresenterShowDelayTests/aReleaseDuringTheWaitCommitsWithoutShowing` on Darwin. Exit 0 and the test name is in the output.
- **Second press closes.** Run `swift test --triple arm64-apple-macosx26.0 --filter PanelPresenterTests/aPressWhileThePanelIsUpTakesItDown` on Darwin. Exit 0.
- **Proof.** Save stdout, stderr, and the exit code under `/tmp/lanterna-verify-evidence/cmd-tab-key-repeat/release-to-switch.log`.

## Gotchas

- Without Input Monitoring the panel closes on the next Cmd+Tab instead of on release. A release recipe run in that mode reports the unmet permission and stops.
- These tests are not a substitute for the key-repeat feature. They do not hold Tab.
- On Linux the commands are blocked. Record the block. Do not skip to a grep of `handleCommandRelease` and call that a drive.
