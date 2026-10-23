# Type to filter

Typing while the filter is active narrows the list on screen to the rows whose names match the query. A panel opened without the filter ignores letters.

## Sub-features

- `filter-open` shows the whole list with filtering on.
- `filter-narrow` drops rows that do not match the next letter.
- `filter-closed` leaves the next appearance unfiltered.

## How to get to it (user POV)

- Press the Show for filtering key. The default is Command-Space.
- Press the Show key (default Command-Tab), then the Start filtering key, then type.
- Type letters while the filter chrome is visible.

## Driving it with scripts/test.sh

Preconditions:

- `bash .cursor/skills/verify-lanterna/scripts/doctor.sh` exited 0.
- No extra seed data. The suite builds its own window list.

- **Open filtering.** Show the panel through the filter invocation. Run `bash scripts/test.sh --filter FilterActivationTests/invokingOnAClosedPanelShowsTheWholeList`. Exit 0. The test's expectation is that the presented list has every row and that the letter `s` then shortens it.
- **Closed panel is not this mode.** A plain appearance swallows a letter. Run `bash scripts/test.sh --filter FilterActivationTests/typingWithoutTheInvocationNarrowsNothing`. Exit 0. The presented list stays at its original count.
- **Next appearance is fresh.** Close the filter and show the panel again. Run `bash scripts/test.sh --filter FilterActivationTests/closingDropsTheQueryForTheNextAppearance`. Exit 0. The next presented list is the whole list.

## Gotchas

- Command-Space is the default filter invocation. A custom `keybindings` entry moves it. The suite uses the defaults.
- Letting go of Command while filtering does not confirm and does not close. Do not treat a key-up as the end of the recipe.
- The macOS SDK is required. If the doctor failed, this journey is not verified.
