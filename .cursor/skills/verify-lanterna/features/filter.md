# Filter

Command+Space opens the switcher ready to type. Letters narrow the list. Releasing Command does not switch while filtering.

## Sub-features

- `filter-open` shows the panel in filter mode.
- `filter-type` narrows rows by the typed text.
- `filter-escape` clears the query, and closes the panel when the query is empty.

## How to get to it (user POV)

- Press Command+Space.
- Type letters.
- Press Escape.

## Driving it with the Lanterna harness

Preconditions:

- Doctor exits 0.
- Darwin with `swift` for the suite below.

- **Open filter.** Run `swift test --triple arm64-apple-macosx26.0 --filter PanelQueryEditingTests` on Darwin. Exit 0.
- **Repeat must not arm.** Run `bash scripts/check-cmd-tab-repeat.sh KR-4`. Exit 0 and the log says the filter does not arm.
- **Proof.** Save the test log under `/tmp/lanterna-verify-evidence/cmd-tab-key-repeat/filter.log`.

## Gotchas

- While Lanterna is running it takes Command+Space from Spotlight. A drive that launches the real binary on a shared Mac changes that shortcut until quit.
- Typing tests need the macOS test host. A Linux run records the block.
- Filter mode stops the Command-release watch. A repeat tick during filtering must not walk the list.
