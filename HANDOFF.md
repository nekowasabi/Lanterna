# Handoff: Cmd+Tab key repeat

The decision for a held invocation key is implemented and the pure checks pass. The presenter tests and the macOS build were not run. This VM is Linux, has no macOS SDK, and the downloaded Swift toolchain stops before compile because `libtool` is missing. Do not treat that as a product failure, and do not treat it as a pass.

## Done

- Root cause: `RegisterEventHotKey` delivers `kEventHotKeyPressed` once per physical press. Holding Tab never produced another hotkey event. The local key monitor is not the Cmd+Tab path, and the listen-only `.flagsChanged` tap was left alone.
- `InvocationKeyRepeat` decides arming, direction, and each tick. `InvocationRepeatClock` waits the system initial delay, then the interval, and the presenter moves the selection while the delivered key stays down and the panel is still walking.
- Shift held with Command selects the narrower backward binding on the next tick.
- Unit tests exist for the pure type and for the presenter, injected so they do not touch a real keyboard.

## Checks

| Item | Result | Meaning |
| --- | --- | --- |
| KR-1 .. KR-6 | exit 0 | `swiftc` harness of `InvocationKeyRepeat` on Linux |
| `bash scripts/check-cmd-tab-repeat.sh` | exit 2 | pure checks passed; KR-P did not run |
| KR-P | exit 2 | blocked: not Darwin |
| `swiftformat --lint` 0.63.0 | exit 0 | `Sources/Lanterna`, `Tests/`, `Package.swift`, the harness |
| `swiftlint --strict` | not run | no Xcode SourceKit, no `nix` |
| `swift build` / `swift test` (`arm64-apple-macosx26.0`) | exit 1 | toolchain invalid: `libtool` missing; no macOS SDK |

Real keyboard behaviour on a Mac is unverified.

## Next step

On a Mac with Xcode:

```bash
env -u SDKROOT -u DEVELOPER_DIR swift test --triple arm64-apple-macosx26.0 --filter 'InvocationKeyRepeatTests|PanelInvocationRepeatTests'
bash scripts/check-cmd-tab-repeat.sh
nix develop --command swiftlint --strict
```

Then hold Cmd and Tab in the running app and confirm the selection walks at the system repeat rate, and that Shift reverses it.
