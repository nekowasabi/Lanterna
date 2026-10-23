# Commit the highlighted row

Confirming the highlighted row focuses that window and closes the panel. The key and a click take the same row.

## Sub-features

- `commit-return` takes the highlighted row and closes the panel.
- `commit-moved` takes the row the choice was moved to, not the row that was highlighted when the panel opened.
- `commit-empty` closes an empty list without focusing a window.

## How to get to it (user POV)

- With the panel up, press Return.
- With the panel up, press keypad Enter.
- Click the row.
- Move the highlight with Down Arrow, J, or N, then press Return.

## Driving it with scripts/test.sh

Preconditions:

- `bash .cursor/skills/verify-lanterna/scripts/doctor.sh` exited 0.
- The suite's fixture list is enough. No user windows are required.

- **Return.** Open the panel and press Return. Run `bash scripts/test.sh --filter PanelExitTests/returnCommitsTheRowTheChoiceWasMovedTo`. Exit 0. The taken row is the one the choice was moved to, and the panel closes.
- **Same path, named key.** Press the commit key. Run `bash scripts/test.sh --filter PanelExitSwitchTests/aKeyCommitTakesTheSameRowWithItsOwnTrigger`. Exit 0. The fake switcher records one take.
- **Empty list.** Commit with nothing shown. Run `bash scripts/test.sh --filter PanelExitTests/anEmptyListCommitsNothingAndSaysSoApartFromACalledOffPress`. Exit 0. Nothing is focused.

## Gotchas

- Return repeats are swallowed. A second Return is not a second focus.
- Releasing Command commits only for a panel that is watching that release. A filtering panel stays up on Command release. Use Return for this recipe.
- The macOS SDK is required. If the doctor failed, this journey is not verified.
