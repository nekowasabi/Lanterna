# Auto-focus a single candidate

While filtering, a query that narrows the list from several rows to one row focuses that window and closes the panel after a short pause. Turning the setting off leaves the panel up until the user confirms.

## Sub-features

- `autofocus-narrow` focuses the only remaining row after the pause.
- `autofocus-burst` does not focus when the next edit widens the list before the pause ends.
- `autofocus-initial` does not focus a list that was already one row.
- `autofocus-empty` does not focus while the query is empty.
- `autofocus-off` does not focus when the setting is off.
- `autofocus-once` focuses at most once.

## How to get to it (user POV)

- Press the Show for filtering key (default Command-Space) and type until one row remains.
- Open the panel, start filtering, and type until one row remains.
- Settings, Appearance, the `Auto-focus single match` toggle. Off keeps the old confirm-with-Return behavior.
- The config key `autoFocusSingleCandidate`. Absent means on. `false` means off.

## Driving it with scripts/test.sh

Preconditions:

- `bash .cursor/skills/verify-lanterna/scripts/doctor.sh` exited 0.
- The contract is `SPEC.md`. The commands below are that contract.

- **Narrow to one.** Type `mai` over Mail and Messages, then let the pause elapse. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/typingDownToOneCandidateActivatesIt`. Exit 0. Mail was focused once and the panel is down.
- **Widen before the pause.** Type `mai`, delete back to `ma` before the pause elapses. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/aBurstThatWidensAgainDoesNotActivate`. Exit 0. Nothing was focused and both rows are still shown.
- **Already one row.** Open filtering over only Mail and let the pause elapse. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/anAlreadySingleListDoesNotActivate`. Exit 0. Nothing was focused.
- **Typing keeps the only row.** Type `m` over that only Mail row. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/typingThatKeepsTheOnlyRowDoesNotActivate`. Exit 0. Nothing was focused.
- **Empty query.** Open filtering over two rows and type nothing. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/anEmptyQueryDoesNotActivate`. Exit 0. Nothing was focused.
- **Clear during the pause.** Type `mai`, press Escape, then let the pause elapse. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/clearingBeforeTheWaitDoesNotActivate`. Exit 0. Nothing was focused and both rows are shown.
- **Setting off.** Turn auto-focus off, type `mai`, let the pause elapse. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/theSettingOffDoesNotActivate`. Exit 0. Nothing was focused and the panel stays up.
- **Once.** Let the pause elapse, then resume it again and press Return. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/activatingTwiceDoesNotSwitchTwice`. Exit 0. The focus happened once.
- **Back from no match.** Type `mailx`, delete to `mail`. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/recoveringFromNoMatchDoesNotActivate`. Exit 0. Nothing was focused.
- **Config.** Load a file with only the version, and round-trip `false`. Run `bash scripts/test.sh --filter 'AutoFocusSingleCandidateTests/absentConfigMeansOn|AutoFocusSingleCandidateTests/falseConfigRoundTrips'`. Exit 0. Absent means on, and false stays false.

## Gotchas

- The pause is 180 milliseconds. A recipe that asserts the focus before resuming the test sleep is early, and a recipe that types the widening edit after the sleep has resumed is late.
- Appending characters does not widen this matcher. The burst recipe widens by deleting.
- A list that opens with one row is not a filter result. Do not count that open as this feature.
- The macOS SDK is required. If the doctor failed, this journey is not verified. Do not mark it passed from a source search.
