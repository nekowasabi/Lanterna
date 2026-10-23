# SPEC: Auto-focus a single filter candidate

When the user is typing a filter and the list on screen narrows from more than one row to exactly one, Lanterna focuses that window and closes the switcher, the same way Return would. The wait is short so a fast burst can still widen the list. The behavior is on by default and can be turned off.

This file is the acceptance contract. Each item below is a command. Pass means that command exits 0. An environment that cannot compile the macOS app records a failed item with the reason, and that result is not a product pass.

## Design

- The setting key is `autoFocusSingleCandidate`. Absent in the config file means on. `SettingsValues.defaults` stores `true`. Saving the default omits the key. Saving off writes `"autoFocusSingleCandidate": false`.
- The setting is shared by both switchers, same as hover to select. The Appearance tab has a toggle titled `Auto-focus single match`.
- English and Japanese usage pages name the key and say the behavior is on by default.
- Arming happens only inside an active filter, only after a query edit changes the query text, only when that edit moves the shown row count from more than one to exactly one, and only when that one row has an identity. An empty query never arms. Opening the panel never arms, including when the list already has one row. Typing that keeps that only row does not arm, because the count did not arrive from more than one. A query edit that moves the count from zero to one does not arm.
- While armed, a later query edit that is still exactly one row restarts the wait. A later edit that leaves any other count, a cleared query, a closed panel, or the setting turning off cancels the wait.
- The wait is `SingleCandidateFocus.settle`, 180 milliseconds. Production waits with `Task.sleep`. Tests pass their own sleep and resume it. The activation uses the same commit path as the commit key: one `switchTo` of the chosen row, then the panel is down. A second resume, or Return after the panel is down, does not call `switchTo` again.
- A list refresh that does not change the query does not arm by itself.

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

The same two rows. The query becomes `mai` (one row), then a deletion makes it `ma` (both rows) before the sleep resumes. After the resume, `switchTo` was not called and the panel is still presented with both rows.

### AF-3 an already single list does not activate

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-3
```

Runs `AutoFocusSingleCandidateTests/anAlreadySingleListDoesNotActivate`.

The panel opens filtering over only Mail. The sleep is resumed with an empty query. `switchTo` was not called and the panel is still presented.

### AF-4 typing that keeps the only row does not activate

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-4
```

Runs `AutoFocusSingleCandidateTests/typingThatKeepsTheOnlyRowDoesNotActivate`.

The panel opens filtering over only Mail. Typing `m` still shows that one row. After the sleep resumes, `switchTo` was not called and the panel is still presented.

### AF-5 an empty query does not activate

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-5
```

Runs `AutoFocusSingleCandidateTests/anEmptyQueryDoesNotActivate`.

The panel opens filtering over Mail and Messages and no query is typed. After the sleep resumes, `switchTo` was not called and the panel is still presented with both rows.

### AF-6 clearing before the wait does not activate

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-6
```

Runs `AutoFocusSingleCandidateTests/clearingBeforeTheWaitDoesNotActivate`.

The query becomes `mai`, then Escape clears it before the sleep resumes. After the resume, `switchTo` was not called and the panel is still presented with both rows.

### AF-7 the setting off does not activate

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-7
```

Runs `AutoFocusSingleCandidateTests/theSettingOffDoesNotActivate`.

`autoFocusSingleCandidate` is false. The query becomes `mai`. After the sleep resumes, `switchTo` was not called and the panel is still presented.

### AF-8 a second fire does not activate again

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-8
```

Runs `AutoFocusSingleCandidateTests/activatingTwiceDoesNotSwitchTwice`.

The query becomes `mai` and the sleep resumes, which activates Mail once. A further resume and a Return keystroke do not call `switchTo` again. The recorded target count is 1.

### AF-9 recovering from no match does not activate

```bash
bash .cursor/skills/verify-lanterna/scripts/check-spec.sh AF-9
```

Runs `AutoFocusSingleCandidateTests/recoveringFromNoMatchDoesNotActivate`.

Over Mail and Messages, the query becomes `mailx` (no row) and a deletion makes it `mail` (one row). After the sleep resumes, `switchTo` was not called and the panel is still presented.

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

- `Sources/Lanterna/UI/SingleCandidateFocus.swift` contains `Duration.milliseconds(180)`.
- `AppConfiguration.knownKeys` contains `autoFocusSingleCandidate`.
- `config/ConfigSchema.pkl` and `config/GenJsonSchema.pkl` contain `autoFocusSingleCandidate`.
- `config/config-schema.json` contains `autoFocusSingleCandidate`.
- `SettingsValues.defaults` sets `autoFocusSingleCandidate: true`.
- `docs/src/content/docs/en/usage.mdx` and `docs/src/content/docs/ja/usage.mdx` contain `autoFocusSingleCandidate`.
- `Sources/Lanterna/UI/SettingsAppearanceView.swift` contains `Auto-focus single match`.
