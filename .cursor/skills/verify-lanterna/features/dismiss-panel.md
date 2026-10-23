# Dismiss the panel

Dismissing the panel closes it and focuses nothing. Escape clears a query first, and a second Escape dismisses when the query is already empty.

## Sub-features

- `dismiss-cancel` closes the panel and focuses nothing.
- `dismiss-clear` clears a query and leaves the panel up.

## How to get to it (user POV)

- With the panel up and the query empty, press Escape.
- Press Command-Period.
- Press Escape once while a query is showing to clear it, then press Escape again to dismiss.

## Driving it with scripts/test.sh

Preconditions:

- `bash .cursor/skills/verify-lanterna/scripts/doctor.sh` exited 0.

- **Cancel.** Press the cancel key. Run `bash scripts/test.sh --filter PanelExitTests/cancellingClosesThePanelAndCommitsNothing`. Exit 0. The panel is down and the fake switcher recorded no take.
- **Clear is not a cancel.** Type a query, then press Escape once. The auto-focus recipe covers the clear. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/clearingBeforeTheWaitDoesNotActivate`. Exit 0. The panel stays up and nothing is focused. Until that test exists, this bullet fails and the cancel bullet above is not a substitute.

## Gotchas

- The first Escape during a query clears. It does not dismiss. A recipe that presses Escape once and expects the panel to close is wrong while a query is showing.
- The macOS SDK is required. If the doctor failed, this journey is not verified.
