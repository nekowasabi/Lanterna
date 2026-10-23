# Cmd+Tab key repeat

Holding Command and holding Tab walks the window list at the system key-repeat rate. Holding Shift as well walks backward when that binding exists. Releasing Tab stops the walk. Releasing Command switches to the chosen window.

## Sub-features

- `repeat-forward` moves to later rows while Tab stays down.
- `repeat-stop` stops when Tab comes up.
- `repeat-backward` moves to earlier rows for Shift+Cmd+Tab.
- `repeat-ignore-filter` does not walk on the filter invocation.

## How to get to it (user POV)

- Hold Command, then hold Tab.
- Hold Shift and Command, then hold Tab.
- Release Tab and keep holding Command.
- Press Command+Space instead, which opens filter mode and must not walk by repeating Tab.

## Driving it with the Lanterna harness

Preconditions:

- `bash scripts/verify-lanterna-doctor.sh` exits 0.
- `Sources/Lanterna/Hotkey/InvocationKeyRepeat.swift` exists. If it does not, the drive fails and the reason is the missing decision type.

KR-1 through KR-6 are the decision function only. The script is not a keyboard session. The panel behavior is KR-P plus a real Mac.

- **Forward.** Run `bash scripts/check-cmd-tab-repeat.sh KR-1`. The log contains `PASS KR-1 tick moves forward` and the command exits 0.
- **Release.** Run `bash scripts/check-cmd-tab-repeat.sh KR-2`. The log contains `PASS KR-2 key up stops`.
- **Backward.** Run `bash scripts/check-cmd-tab-repeat.sh KR-3`. The log contains `PASS KR-3 command and shift is backward`.
- **Filter.** Run `bash scripts/check-cmd-tab-repeat.sh KR-4`. The log contains `PASS KR-4 filter does not arm`.
- **Timing.** Run `bash scripts/check-cmd-tab-repeat.sh KR-5`. The log contains `PASS KR-5 one second stays one second` and `PASS KR-5 a negative remainder becomes zero`.
- **Custom key.** Run `bash scripts/check-cmd-tab-repeat.sh KR-6`. The log contains `PASS KR-6 a different key does not match`.
- **Panel walk.** On macOS, run `bash scripts/check-cmd-tab-repeat.sh KR-P`. The log contains `PASS KR-P`. On Linux the same command prints `BLOCKED KR-P` and exits 2. Record that exit. Do not rewrite it as a pass.
- **Proof.** Save the log. Run `LANTERNA_VERIFY_EVIDENCE=/tmp/lanterna-verify-evidence bash scripts/check-cmd-tab-repeat.sh KR-1`. The file `/tmp/lanterna-verify-evidence/cmd-tab-key-repeat/check-KR-1.log` exists after cleanup.

## Gotchas

- Carbon's hotkey event fires once per press. A test that only calls `handleHotkey` twice is two presses, not a hold.
- The local key monitor absorbs Tab so a hold cannot move twice if both paths ever see it. Driving only that monitor does not prove this feature.
- KR-1 through KR-6 are the decision function only. They fail closed when the decision type is missing. The panel behavior is KR-P plus a real Mac.
- Linux has no macOS SDK. KR-P stays blocked there. The real keyboard on a Mac stays unverified until KR-P runs on Darwin.
