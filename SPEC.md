# SPEC: Auto-focus a single filter candidate

When the user is typing a filter and the list on screen narrows from more than one row to exactly one, Lanterna focuses that window and closes the switcher, the same way Return would. The wait is long enough that a normal gap between letters does not count as a choice. Keystrokes in a short stretch after that close stay with Lanterna. The behavior is on by default and can be turned off.

This file is the acceptance contract. Each item below is a command. Pass means that command exits 0. An environment that cannot compile the macOS app records a failed item with the reason, and that result is not a product pass.

## Design

- The setting key is `autoFocusSingleCandidate`. Absent in the config file means on. `SettingsValues.defaults` stores `true`. Saving the default omits the key. Saving off writes `"autoFocusSingleCandidate": false`.
- The setting is shared by both switchers, same as hover to select. The Appearance tab has a toggle titled `Auto-focus single match`. The toggle sits after Reorder rows, in the same order as this paragraph and the usage pages: Hover to select, Scroll to select, Number jump, Reorder rows, then Auto-focus single match.
- English and Japanese usage pages name the key and say the behavior is on by default.
- A wait starts only inside an active filter, only after a query edit changes the query text, only when that edit moves the shown row count from more than one to exactly one, and only when that one row has an identity. An empty query never starts one. Opening the panel never starts one, including when the list already has one row. Typing that keeps that only row does not start one, because the count did not arrive from more than one. A query edit that moves the count from zero to one does not start one. A wait that has already started can restart without a query edit when the single row's identity changes.
- While armed, a later query edit that is still exactly one row restarts the wait. While armed, a list change that keeps one row but replaces that row's identity restarts the wait on the new row. A later edit that leaves any other count, a cleared query, a closed panel, or the setting turning off cancels the wait. Return during the wait commits once through the commit key and the later resume does not commit again. Closing the panel during the wait, or turning the setting off during the wait, leaves `switchTo` uncalled.
- The wait is `SingleCandidateFocus.settle`, 400 milliseconds. Production waits with `Task.sleep`. Tests pass their own sleep and resume it. The activation uses the same commit path as the commit key: one `switchTo` of the chosen row, then the panel is down. A second resume does not call `switchTo` again.
- 400 milliseconds is a choice, not a measurement from this repo. Within-word gaps commonly fall under 300 milliseconds, so the previous 180 millisecond wait could elapse between two letters. 400 sits past that cluster and still reads as a short pause.
- After an auto-commit, keystrokes for `SingleCandidateFocus.swallow` (250 milliseconds) return `.absorbed` and do not reach the focused app. The stretch does not extend when a key arrives. A commit key or a click does not start it. Return immediately after the auto-commit is `.absorbed`, and `switcher.targets.count` stays 1. A Return after the stretch is `.passedThrough` and still does not call `switchTo`. 250 milliseconds is a choice. It covers one late key without holding the keyboard for the next word.
- A list refresh that does not change the query does not arm by itself when no wait is armed.
- Current behavior, left as an open question for a human: a query edit that moves the count from zero to one does not arm, and a scope switch that lands on one row does not arm. Neither path is a typed narrowing from several rows. Whether either should arm is not decided here.

The matcher cannot widen a result by appending characters. The 2 to 1 to 2 case is produced by a later edit that widens, which a deletion does. The wait is what lets that edit land before the focus.

## Acceptance checks

Run every item from the repo root:

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh
```

One item:

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-1
```

The script prints `ID PASS` or `ID FAIL` and exits 0 only when every selected item passes.

### AF-1 typing to one candidate activates it

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-1
```

Runs `AutoFocusSingleCandidateTests/typingDownToOneCandidateActivatesIt`.

The panel is filtering over Mail and Messages. The query becomes `mai`, which shows only Mail. After the settle sleep resumes once, `switchTo` was called once for Mail and the panel is not presented.

### AF-2 a fast burst that widens again does not activate

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-2
```

Runs `AutoFocusSingleCandidateTests/aBurstThatWidensAgainDoesNotActivate`.

The same two rows. The query becomes `mai` (one row), which arms one settle sleep, then a deletion makes it `ma` (both rows) before the sleep resumes. After the resume, that one sleep is still the only one recorded, `switchTo` was not called, and the panel is still presented with both rows.

### AF-3 an already single list does not activate

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-3
```

Runs `AutoFocusSingleCandidateTests/anAlreadySingleListDoesNotActivate`.

The panel opens filtering over only Mail. No settle sleep is armed. The sleep is resumed with an empty query. `switchTo` was not called and the panel is still presented. This path never arms, so an empty duration list is the observation. Deleting the feature leaves that observation unchanged. AF-2, AF-6, and AF-9 are the checks that fail when arming is removed.

### AF-4 typing that keeps the only row does not activate

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-4
```

Runs `AutoFocusSingleCandidateTests/typingThatKeepsTheOnlyRowDoesNotActivate`.

The panel opens filtering over only Mail. Typing `m` still shows that one row and does not arm a settle sleep, because the count did not arrive from more than one. After the sleep resumes, `switchTo` was not called and the panel is still presented. An empty duration list is the observation. Deleting the feature leaves it unchanged.

### AF-5 an empty query does not activate

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-5
```

Runs `AutoFocusSingleCandidateTests/anEmptyQueryDoesNotActivate`.

The panel opens filtering over Mail and Messages and no query is typed. No settle sleep is armed. After the sleep resumes, `switchTo` was not called and the panel is still presented with both rows. An empty duration list is the observation. Deleting the feature leaves it unchanged.

### AF-6 clearing before the wait does not activate

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-6
```

Runs `AutoFocusSingleCandidateTests/clearingBeforeTheWaitDoesNotActivate`.

The query becomes `mai`, which arms one settle sleep, then Escape clears it before the sleep resumes. After the resume, that one sleep is still the only one recorded, `switchTo` was not called, and the panel is still presented with both rows.

### AF-7 the setting off does not activate

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-7
```

Runs `AutoFocusSingleCandidateTests/theSettingOffDoesNotActivate`.

`autoFocusSingleCandidate` is false before any typing. The query becomes `mai`. No settle sleep is armed. After the sleep resumes, `switchTo` was not called and the panel is still presented. An empty duration list is the observation. Deleting the feature leaves it unchanged. Turning the setting off during an armed wait is AF-14.

### AF-8 a second fire does not activate again

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-8
```

Runs `AutoFocusSingleCandidateTests/activatingTwiceDoesNotSwitchTwice`.

The query becomes `mai` and the sleep resumes, which activates Mail once. Return immediately after that close is `.absorbed`, and `switcher.targets.count` stays 1. After the swallow stretch, Return is `.passedThrough` and the target count is still 1. A further resume does not call `switchTo` again.

### AF-9 recovering from no match does not activate

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-9
```

Runs `AutoFocusSingleCandidateTests/recoveringFromNoMatchDoesNotActivate`.

Over Mail and Messages, the query becomes `mailx` (no row). Reaching `mai` and then `mail` arms the settle sleep twice, and `mailx` cancels it. A deletion makes the query `mail` (one row, from zero). That step does not arm again, so two sleeps are still recorded. After the resume, `switchTo` was not called and the panel is still presented. The zero-to-one step is current behavior and an open question. See the design list.

### AF-10 absent config means on, and false round-trips

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-10
```

Runs `AutoFocusSingleCandidateTests/absentConfigMeansOn` and `AutoFocusSingleCandidateTests/falseConfigRoundTrips`.

`{"version": 1}` loads as on. A value of false is written as `"autoFocusSingleCandidate": false` and loads as off. A non-boolean value is rejected.

### AF-11 the wait and the setting are present in source

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-11
```

This check does not compile. It exits 0 only when all of these are true:

- `Sources/Lanterna/UI/SingleCandidateFocus.swift` contains `Duration.milliseconds(400)` and `Duration.milliseconds(250)`.
- `Sources/Lanterna/UI/PanelKeyCommands.swift` contains `postCommitSwallow.arm` and `postCommitSwallow.swallows`.
- `AppConfiguration.knownKeys` contains `autoFocusSingleCandidate`.
- `config/ConfigSchema.pkl` and `config/GenJsonSchema.pkl` contain `autoFocusSingleCandidate`.
- `config/config-schema.json` contains `autoFocusSingleCandidate`.
- `SettingsValues.defaults` sets `autoFocusSingleCandidate: true`.
- `docs/src/content/docs/en/usage.mdx` and `docs/src/content/docs/ja/usage.mdx` contain `autoFocusSingleCandidate`.
- `Sources/Lanterna/UI/SettingsAppearanceView.swift` contains `Auto-focus single match` after `Reorder rows`.

### AF-12 Return during the wait commits once

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-12
```

Runs `AutoFocusSingleCandidateTests/returnDuringTheWaitCommitsOnce`.

The query becomes `mai` and one settle sleep is armed. Return before that sleep resumes commits Mail once (`switcher.targets.count` is 1). Resuming the sleep does not commit again. A letter after that user commit is `.passedThrough`, because only an auto-commit keeps keystrokes.

### AF-13 closing the panel during the wait does not commit

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-13
```

Runs `AutoFocusSingleCandidateTests/closingDuringTheWaitDoesNotCommit`.

The query becomes `mai` and one settle sleep is armed. Command-Period closes the panel before the sleep resumes. After the resume, `switcher.targets` is empty. The assertion is `isEmpty` because the formatter rejects a comparison with zero.

### AF-14 turning the setting off during the wait does not commit

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-14
```

Runs `AutoFocusSingleCandidateTests/turningTheSettingOffDuringTheWaitDoesNotCommit`.

The query becomes `mai` and one settle sleep is armed. The setting is then turned off. After the sleep resumes, `switcher.targets` is empty and the panel is still presented. The assertion is `isEmpty` because the formatter rejects a comparison with zero.

### AF-15 swapping the single candidate restarts the wait

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-15
```

Runs `AutoFocusSingleCandidateTests/swappingTheSingleCandidateRearms`.

The query becomes `mai`, which arms one settle sleep on Mail's Inbox. The presented list is replaced by a different single Mail row, Drafts, without a query edit. A second settle sleep is armed. After both sleeps resume, `switcher.targets.count` is 1 and the taken row is Drafts.

Mac-unverified. AF-1 through AF-10 and AF-12 through AF-15 compile and run only on macOS 26 arm64. This environment must not report them as passed. AF-11 does not compile.
