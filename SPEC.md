# Cmd+Tab key repeat

Acceptance checks for one bug. While Command stays down, holding Tab moves the selection at the system key-repeat rate. Shift+Cmd+Tab, when that direction is bound, moves backward. A discrete press still moves once.

The checks are commands. Exit 0 is a pass. Exit 1 is a fail. Exit 2 means the check could not run here. An exit of 2 is not a pass.

## What is wrong

`HotkeyManager` registers Carbon hotkeys and installs a handler for `kEventHotKeyPressed` only. Carbon sends that event once per physical press. It does not send it again for keyboard autorepeat. `PanelPresenter.handleHotkey` is the path that moves the selection for Cmd+Tab, and the presenter records the measurement that a three-second hold produced one press.

Tab that reaches the panel through the local key monitor is not the repeat path. Invocation bindings already hold Tab, and a Tab press is absorbed there so one physical press cannot move the selection twice.

## Checks

Run every item with:

```bash
bash scripts/check-cmd-tab-repeat.sh
```

Run one item by passing its id, for example `bash scripts/check-cmd-tab-repeat.sh KR-1`.

KR-1 through KR-6 exercise only `InvocationKeyRepeat`. They do not open a panel or read the keyboard. The list walk is KR-P plus a real Mac.

### KR-1 Forward hold

A forward invocation that leaves the panel walking arms a repeat. While the invocation key stays down, the first repeat waits the initial delay and each later repeat waits the interval. Each one moves forward.

```bash
bash scripts/check-cmd-tab-repeat.sh KR-1
```

### KR-2 Key release

A repeat tick with the invocation key up stops. No further move is owed.

```bash
bash scripts/check-cmd-tab-repeat.sh KR-2
```

### KR-3 Backward hold

A backward invocation arms a repeat. If both directions share the held key, the tick uses the binding whose modifiers fit the keys that are down and that asks for the most modifiers. Command alone moves forward. Command and Shift move backward.

```bash
bash scripts/check-cmd-tab-repeat.sh KR-3
```

### KR-4 Do not arm a dead walk

The filter invocation does not arm a navigation repeat. A press that will dismiss the panel, or a panel that is no longer walking, does not arm one either. A tick in that state stops.

```bash
bash scripts/check-cmd-tab-repeat.sh KR-4
```

### KR-5 Repeat timing

`InvocationKeyRepeat.timing(initialDelay:interval:)` keeps values that are already in seconds. `.seconds(1)` and `.seconds(0.1)` stay those values. A negative initial delay becomes `.zero`. A zero or negative interval becomes `.milliseconds(1)`.

A remainder is clamped through the same function. `timing(initialDelay: .seconds(1) - .seconds(0.4), interval: .seconds(0.1))` keeps a 0.6 second initial delay. `timing(initialDelay: .seconds(0.2) - .seconds(1), interval: .seconds(0.1))` has initial delay `.zero`.

With a show delay, the presenter subtracts the elapsed time since the press before that clamp. The first repeat after the panel appears waits max(0, initialDelay - elapsed). It does not wait the show delay plus a full initial delay.

```bash
bash scripts/check-cmd-tab-repeat.sh KR-5
```

### KR-6 Pressed key, not a fixed Tab

The repeat polls the physical key that Carbon delivered. A custom invocation key repeats only while that key is down.

```bash
bash scripts/check-cmd-tab-repeat.sh KR-6
```

### KR-P Presenter

On macOS, with Xcode or the Command Line Tools, the presenter tests are the observable walk. They open a panel, hold the key through an injected sleep, and read the chosen row.

After the invocation key is released, `RepeatSleep.waits` does not grow. After Escape closes the panel, `RepeatSleep.waits` does not grow.

```bash
env -u SDKROOT -u DEVELOPER_DIR swift test --triple arm64-apple-macosx26.0 --filter 'InvocationKeyRepeatTests|PanelInvocationRepeatTests'
```

`scripts/check-cmd-tab-repeat.sh` runs this only when `uname` is Darwin and `swift` exists. Elsewhere the item is blocked.

## Out of scope

Real keyboard behavior on a Mac is not claimed by a passing Linux run. The app is a menu-bar SwiftUI/AppKit process and does not start on Linux.
