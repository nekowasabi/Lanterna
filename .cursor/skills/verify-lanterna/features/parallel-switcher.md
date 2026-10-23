# Parallel switcher

Option+Tab opens a second switcher. By default it lists the front app's windows. Shift+Option+Tab walks backward. Releasing Option switches.

## Sub-features

- `parallel-open` shows the panel for Option+Tab.
- `parallel-reverse` walks backward for Shift+Option+Tab.
- `parallel-off` leaves those keys with the front app when the switcher is disabled.

## How to get to it (user POV)

- Hold Option and press Tab.
- Hold Shift and Option and press Tab.
- Turn the parallel switcher off in Settings, under Switchers.

## Driving it with the Lanterna harness

Preconditions:

- Doctor exits 0.
- Darwin with `swift` for the suite below.

- **Bindings.** Run `swift test --triple arm64-apple-macosx26.0 --filter ParallelHotkeyTests` on Darwin. Exit 0.
- **Walk.** Run `swift test --triple arm64-apple-macosx26.0 --filter ParallelPresenterTests` on Darwin. Exit 0.
- **Proof.** Save the log under `/tmp/lanterna-verify-evidence/cmd-tab-key-repeat/parallel.log`.

## Gotchas

- The parallel switcher is on by default. A disabled configuration is a different entry point and is not verified by the enabled tests.
- Option+Tab repeat uses the same decision as Cmd+Tab. KR-1 covers the forward role, not the Option modifier on a live keyboard.
- Linux cannot run these tests. Record the block.
