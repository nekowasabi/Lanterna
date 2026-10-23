import Foundation
@testable import Lanterna
import Testing

// MARK: - InvocationKeyRepeatTests

/// The hold decision, with no panel and no keyboard.
///
/// These are the same answers `scripts/check-invocation-key-repeat.swift`
/// asks. The script is what a host without the macOS SDK can run. This
/// suite is what `swift test` runs.
struct InvocationKeyRepeatTests {

  @Test
  func aForwardHoldArmsAndMoves() {
    #expect(InvocationKeyRepeat.shouldArm(role: .forward, panelStaysUpWalking: true))
    #expect(
      InvocationKeyRepeat.tick(keyIsDown: true, panelStillWalking: true, direction: .forward)
        == .move(.forward)
    )
  }

  @Test
  func aKeyThatCameUpStops() {
    #expect(
      InvocationKeyRepeat.tick(keyIsDown: false, panelStillWalking: true, direction: .forward)
        == .stop
    )
  }

  @Test
  func shiftWithCommandWalksBackward() {
    #expect(InvocationKeyRepeat.shouldArm(role: .backward, panelStaysUpWalking: true))
    let bindings = [
      InvocationKeyRepeat.Binding(
        keyCode: 48,
        modifiers: HeldModifiers(command: true),
        direction: .forward
      ),
      InvocationKeyRepeat.Binding(
        keyCode: 48,
        modifiers: HeldModifiers(shift: true, command: true),
        direction: .backward
      ),
    ]
    #expect(
      InvocationKeyRepeat.directionWhileHeld(
        bindings: bindings,
        keyCode: 48,
        held: HeldModifiers(command: true)
      ) == .forward
    )
    #expect(
      InvocationKeyRepeat.directionWhileHeld(
        bindings: bindings,
        keyCode: 48,
        held: HeldModifiers(shift: true, command: true)
      ) == .backward
    )
  }

  @Test
  func filterAndAClosingPanelDoNotArm() {
    #expect(!InvocationKeyRepeat.shouldArm(role: .filter, panelStaysUpWalking: true))
    #expect(!InvocationKeyRepeat.shouldArm(role: .forward, panelStaysUpWalking: false))
    #expect(
      InvocationKeyRepeat.tick(keyIsDown: true, panelStillWalking: false, direction: .forward)
        == .stop
    )
    #expect(
      InvocationKeyRepeat.tick(keyIsDown: true, panelStillWalking: true, direction: nil) == .stop
    )
  }

  @Test
  func systemUnitsMatchTheKeyboardSettingsScale() {
    let timing = InvocationKeyRepeat.timingFromSystemUnits(initialUnits: 60, intervalUnits: 6)
    #expect(timing.initialDelay == .milliseconds(1_000))
    #expect(timing.interval == .milliseconds(100))
    let clamped = InvocationKeyRepeat.timing(initialDelay: .seconds(-1), interval: .zero)
    #expect(clamped.initialDelay == .zero)
    #expect(clamped.interval >= .milliseconds(1))
  }

  @Test
  func theRepeatFollowsTheKeyThatWasPressed() {
    let bindings = [
      InvocationKeyRepeat.Binding(
        keyCode: 42,
        modifiers: HeldModifiers(command: true),
        direction: .forward
      )
    ]
    #expect(
      InvocationKeyRepeat.directionWhileHeld(
        bindings: bindings,
        keyCode: 42,
        held: HeldModifiers(command: true)
      ) == .forward
    )
    #expect(
      InvocationKeyRepeat.directionWhileHeld(
        bindings: bindings,
        keyCode: 48,
        held: HeldModifiers(command: true)
      ) == nil
    )
  }

}
