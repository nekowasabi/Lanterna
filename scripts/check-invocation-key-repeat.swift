import Foundation

// Acceptance harness for SPEC.md KR-1 through KR-6.
// Compiled together with Sources/Lanterna/Hotkey/InvocationKeyRepeat.swift
// so the checks call the production type. A missing or drifted API fails
// the compile, which is a fail.

func expect(_ condition: Bool, _ name: String, failures: inout [String]) {
  if condition {
    print("PASS \(name)")
  } else {
    print("FAIL \(name)")
    failures.append(name)
  }
}

func tabBinding(_ direction: InvocationKeyRepeat.Direction, shift: Bool) -> InvocationKeyRepeat.Binding {
  InvocationKeyRepeat.Binding(
    keyCode: 48,
    modifiers: HeldModifiers(shift: shift, command: true),
    direction: direction
  )
}

let only = CommandLine.arguments.dropFirst().first
func wanted(_ id: String) -> Bool {
  only == nil || only == "all" || only == id
}

// MARK: - CheckInvocationKeyRepeat

@main
enum CheckInvocationKeyRepeat {
  static func main() {
    var failures = [String]()
    run(&failures)
    if failures.isEmpty {
      exit(0)
    }
    exit(1)
  }
}

func run(_ failures: inout [String]) {
  if wanted("KR-1") {
    expect(
      InvocationKeyRepeat.shouldArm(role: .forward, panelStaysUpWalking: true),
      "KR-1 forward hold arms",
      failures: &failures
    )
    let step = InvocationKeyRepeat.tick(
      keyIsDown: true,
      panelStillWalking: true,
      direction: .forward
    )
    expect(step == .move(.forward), "KR-1 tick moves forward", failures: &failures)
  }

  if wanted("KR-2") {
    let step = InvocationKeyRepeat.tick(
      keyIsDown: false,
      panelStillWalking: true,
      direction: .forward
    )
    expect(step == .stop, "KR-2 key up stops", failures: &failures)
  }

  if wanted("KR-3") {
    expect(
      InvocationKeyRepeat.shouldArm(role: .backward, panelStaysUpWalking: true),
      "KR-3 backward hold arms",
      failures: &failures
    )
    let bindings = [
      tabBinding(.forward, shift: false),
      tabBinding(.backward, shift: true),
    ]
    let forward = InvocationKeyRepeat.directionWhileHeld(
      bindings: bindings,
      keyCode: 48,
      held: HeldModifiers(command: true)
    )
    let backward = InvocationKeyRepeat.directionWhileHeld(
      bindings: bindings,
      keyCode: 48,
      held: HeldModifiers(shift: true, command: true)
    )
    expect(forward == .forward, "KR-3 command alone is forward", failures: &failures)
    expect(backward == .backward, "KR-3 command and shift is backward", failures: &failures)
    let step = InvocationKeyRepeat.tick(
      keyIsDown: true,
      panelStillWalking: true,
      direction: backward
    )
    expect(step == .move(.backward), "KR-3 tick moves backward", failures: &failures)
  }

  if wanted("KR-4") {
    expect(
      !InvocationKeyRepeat.shouldArm(role: .filter, panelStaysUpWalking: true),
      "KR-4 filter does not arm",
      failures: &failures
    )
    expect(
      !InvocationKeyRepeat.shouldArm(role: .forward, panelStaysUpWalking: false),
      "KR-4 a closing panel does not arm",
      failures: &failures
    )
    let stopped = InvocationKeyRepeat.tick(
      keyIsDown: true,
      panelStillWalking: false,
      direction: .forward
    )
    let undecided = InvocationKeyRepeat.tick(
      keyIsDown: true,
      panelStillWalking: true,
      direction: nil
    )
    expect(stopped == .stop, "KR-4 a panel that is not walking stops", failures: &failures)
    expect(undecided == .stop, "KR-4 no matching binding stops", failures: &failures)
  }

  if wanted("KR-5") {
    let timing = InvocationKeyRepeat.timingFromSystemUnits(initialUnits: 60, intervalUnits: 6)
    expect(
      timing.initialDelay == .milliseconds(1_000),
      "KR-5 initial delay is one second",
      failures: &failures
    )
    expect(timing.interval == .milliseconds(100), "KR-5 interval is 100 ms", failures: &failures)
    let clamped = InvocationKeyRepeat.timing(initialDelay: .seconds(-1), interval: .zero)
    expect(clamped.initialDelay == .zero, "KR-5 negative delay becomes zero", failures: &failures)
    expect(clamped.interval >= .milliseconds(1), "KR-5 interval cannot be zero", failures: &failures)
  }

  if wanted("KR-6") {
    let bindings = [
      InvocationKeyRepeat.Binding(
        keyCode: 42,
        modifiers: HeldModifiers(command: true),
        direction: .forward
      )
    ]
    let held = InvocationKeyRepeat.directionWhileHeld(
      bindings: bindings,
      keyCode: 42,
      held: HeldModifiers(command: true)
    )
    let other = InvocationKeyRepeat.directionWhileHeld(
      bindings: bindings,
      keyCode: 48,
      held: HeldModifiers(command: true)
    )
    expect(held == .forward, "KR-6 the pressed key still matches", failures: &failures)
    expect(other == nil, "KR-6 a different key does not match", failures: &failures)
  }
}
