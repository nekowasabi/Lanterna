# Auto-focus a single candidate

While filtering, a query that narrows the list from several rows to one row focuses that window and closes the panel after a 400 millisecond pause. Keystrokes for 250 milliseconds after that close stay with Lanterna. Turning the setting off leaves the panel up until the user confirms.

## Sub-features

- `autofocus-narrow` focuses the only remaining row after the pause.
- `autofocus-burst` arms the pause, then does not focus when the next edit widens the list before the pause ends.
- `autofocus-initial` does not focus a list that was already one row, and does not arm.
- `autofocus-empty` does not focus while the query is empty, and does not arm.
- `autofocus-off` does not focus when the setting is off before typing, and does not arm.
- `autofocus-once` focuses at most once, and keeps Return in the 250 millisecond stretch after the auto-commit.
- `autofocus-return-during-wait` commits once if Return arrives before the pause ends.
- `autofocus-close-during-wait` does not focus if the panel closes during the pause.
- `autofocus-off-during-wait` does not focus if the setting turns off during the pause.
- `autofocus-swap` restarts the pause when the armed row is replaced by a different single row.

## How to get to it (user POV)

- Press the Show for filtering key (default Command-Space) and type until one row remains.
- Open the panel, start filtering, and type until one row remains.
- Settings, Appearance. The toggle order is Hover to select, Scroll to select, Number jump, Reorder rows, then `Auto-focus single match`. Off keeps the old confirm-with-Return behavior.
- The config key `autoFocusSingleCandidate`. Absent means on. `false` means off.

## Driving it with scripts/test.sh

Preconditions:

- `bash .cursor/skills/verify-lanterna/scripts/doctor.sh` exited 0.
- The contract is `SPEC.md`. The commands below are that contract.

- **Narrow to one.** Type `mai` over Mail and Messages, then let the pause elapse. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/typingDownToOneCandidateActivatesIt`. Exit 0. Mail was focused once and the panel is down.
- **Widen before the pause.** Type `mai`, delete back to `ma` before the pause elapses. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/aBurstThatWidensAgainDoesNotActivate`. Exit 0. One settle sleep was armed, nothing was focused, and both rows are still shown.
- **Already one row.** Open filtering over only Mail and let the pause elapse. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/anAlreadySingleListDoesNotActivate`. Exit 0. No settle sleep was armed and nothing was focused.
- **Typing keeps the only row.** Type `m` over that only Mail row. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/typingThatKeepsTheOnlyRowDoesNotActivate`. Exit 0. No settle sleep was armed and nothing was focused.
- **Empty query.** Open filtering over two rows and type nothing. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/anEmptyQueryDoesNotActivate`. Exit 0. No settle sleep was armed and nothing was focused.
- **Clear during the pause.** Type `mai`, press Escape, then let the pause elapse. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/clearingBeforeTheWaitDoesNotActivate`. Exit 0. One settle sleep was armed, nothing was focused, and both rows are shown.
- **Setting off.** Turn auto-focus off, type `mai`, let the pause elapse. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/theSettingOffDoesNotActivate`. Exit 0. No settle sleep was armed, nothing was focused, and the panel stays up.
- **Once.** Let the pause elapse, then press Return at once, then again after the swallow stretch. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/activatingTwiceDoesNotSwitchTwice`. Exit 0. The first Return is absorbed, the later Return passes through, and the focus happened once.
- **Return during the pause.** Type `mai`, press Return before the pause elapses. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/returnDuringTheWaitCommitsOnce`. Exit 0. `switcher.targets.count` is 1 after the resume.
- **Close during the pause.** Type `mai`, press Command-Period, then let the pause elapse. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/closingDuringTheWaitDoesNotCommit`. Exit 0. `switcher.targets` is empty.
- **Setting off during the pause.** Type `mai`, turn the setting off, then let the pause elapse. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/turningTheSettingOffDuringTheWaitDoesNotCommit`. Exit 0. `switcher.targets` is empty and the panel stays up.
- **Swap the row.** Type `mai`, replace the single row with a different Mail row, then let the pause elapse. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/swappingTheSingleCandidateRearms`. Exit 0. `switcher.targets.count` is 1 and the taken row is Drafts.
- **Back from no match.** Type `mailx`, delete to `mail`. Run `bash scripts/test.sh --filter AutoFocusSingleCandidateTests/recoveringFromNoMatchDoesNotActivate`. Exit 0. Two settle sleeps were armed and then cancelled, the deletion from no match does not arm a third, and nothing was focused.
- **Config.** Load a file with only the version, and round-trip `false`. Run `bash scripts/test.sh --filter 'AutoFocusSingleCandidateTests/absentConfigMeansOn|AutoFocusSingleCandidateTests/falseConfigRoundTrips'`. Exit 0. Absent means on, and false stays false.

## Gotchas

- The pause is 400 milliseconds. The swallow stretch after an auto-commit is 250 milliseconds. A recipe that asserts the focus before resuming the test sleep is early, and a recipe that types the widening edit after the sleep has resumed is late.
- Appending characters does not widen this matcher. The burst recipe widens by deleting.
- A list that opens with one row is not a filter result. Do not count that open as this feature.
- A query edit from zero rows to one row does not arm. A scope switch that lands on one row does not arm. Both are current behavior and an open question.
- The macOS SDK is required. If the doctor failed, this journey is not verified. Do not mark it passed from a source search.
