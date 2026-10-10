import AppKit
import Carbon.HIToolbox
import CoreGraphics
@testable import Lanterna
import Testing

/// One row of the named owner, so the scope decides which rows stay.
@MainActor
private func parallelRow(
  _ windowID: CGWindowID,
  owner: pid_t,
  app: String,
  title: String
) -> WindowItem {
  WindowItem(
    id: WindowItem.Identifier(windowID: windowID),
    ownerProcessIdentifier: owner,
    appName: app,
    bundleIdentifier: nil,
    windowTitle: title,
    kind: .standard,
    isMinimized: false,
    icon: NSImage(size: NSSize(width: 1, height: 1))
  )
}

// MARK: - ParallelPresenterTests

/// The parallel switcher opens the same panel on its own settings: the
/// front application alone, with the scope toggle kept to the showing.
@MainActor
struct ParallelPresenterTests {

  // MARK: Internal

  @Test
  func parallelOpensOnTheFrontApplicationAlone() {
    let fixture = twoAppFixture(front: safari)
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)

    #expect(fixture.surface.isPresented)
    let shown = fixture.surface.presentedLists.last ?? []
    #expect(shown.count == 3)
    #expect(shown.allSatisfy { $0.ownerProcessIdentifier == safari })
    #expect(fixture.surface.scopeBands.last.flatMap { $0 } != nil)
  }

  @Test
  func mainOpensOnEveryApplication() {
    let fixture = twoAppFixture(front: safari)
    fixture.presenter.handleHotkey(.forward, deliveryDelay: nil)

    let shown = fixture.surface.presentedLists.last ?? []
    #expect(shown.count == 5)
    #expect(fixture.surface.scopeBands.last.flatMap { $0 } == nil)
  }

  @Test
  func scopeToggleAppliesToTheShowingAlone() {
    let fixture = twoAppFixture(front: safari)
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)
    _ = fixture.presenter.handleKeyStroke(PanelKeystroke(
      keyCode: UInt16(kVK_ANSI_Slash),
      modifiers: .command,
      isARepeat: false
    ))

    #expect(fixture.surface.updatedLists.last?.count == 5)
    fixture.presenter.modifierFlagsChanged([])
    fixture.presenter.handleOptionRelease()
    #expect(!fixture.surface.isPresented)

    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)
    let reopened = fixture.surface.presentedLists.last ?? []
    #expect(reopened.count == 3)
    #expect(reopened.allSatisfy { $0.ownerProcessIdentifier == safari })
  }

  @Test
  func parallelReverseWalksBackwards() {
    let fixture = twoAppFixture(front: safari)
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)
    let first = fixture.surface.shownSelections.last
    fixture.presenter.handleHotkey(.parallelReverse, deliveryDelay: nil)

    #expect(fixture.surface.isPresented)
    #expect(fixture.surface.presentedLists.count == 1)
    #expect(fixture.surface.shownSelections.last != first)
  }

  @Test
  func optionPressWithoutCommandOpens() {
    let fixture = twoAppFixture(front: safari, commandIsHeld: false, heldModifiers: .maskAlternate)
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)

    #expect(fixture.surface.isPresented)
  }

  @Test
  func optionReleaseCommitsAnOptionOpenedPanel() {
    let fixture = twoAppFixture(front: safari, heldModifiers: .maskAlternate)
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)

    #expect(fixture.surface.isPresented)
    fixture.presenter.handleOptionRelease()
    #expect(!fixture.surface.isPresented)
    #expect(fixture.log.lines.contains(where: { $0.hasPrefix("committed ") }))
  }

  @Test
  func commandReleaseCommitsNothingWhileOptionIsHeld() {
    let fixture = twoAppFixture(front: safari, commandIsHeld: false, heldModifiers: .maskAlternate)
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)

    #expect(fixture.surface.isPresented)
    fixture.presenter.handleCommandRelease()
    #expect(fixture.surface.isPresented)
    #expect(!fixture.log.lines.contains(where: { $0.hasPrefix("committed ") }))
  }

  @Test
  func commandReleaseAfterOptionReleaseCommits() {
    let fixture = twoAppFixture(front: safari, heldModifiers: [.maskCommand, .maskAlternate])
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)

    #expect(fixture.surface.isPresented)
    fixture.presenter.modifierFlagsChanged([.maskCommand])
    fixture.presenter.handleOptionRelease()
    #expect(fixture.surface.isPresented)
    #expect(!fixture.log.lines.contains(where: { $0.hasPrefix("committed ") }))
    fixture.presenter.modifierFlagsChanged([])
    fixture.presenter.handleCommandRelease()
    #expect(!fixture.surface.isPresented)
    #expect(fixture.log.lines.contains(where: { $0.hasPrefix("committed ") }))
  }

  @Test
  func controlReleaseCommitsNothing() {
    let fixture = twoAppFixture(front: safari, heldModifiers: [.maskAlternate, .maskControl])
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)

    #expect(fixture.surface.isPresented)
    fixture.presenter.modifierFlagsChanged(.maskAlternate)
    #expect(fixture.surface.isPresented)
    #expect(!fixture.log.lines.contains(where: { $0.hasPrefix("committed ") }))
  }

  @Test
  func filteringOptionReleaseCommitsNothing() {
    let fixture = twoAppFixture(front: safari, heldModifiers: .maskAlternate)
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)
    fixture.presenter.switchToFiltering()
    fixture.presenter.handleOptionRelease()

    #expect(fixture.surface.isPresented)
    #expect(!fixture.log.lines.contains(where: { $0.hasPrefix("committed ") }))
  }

  @Test
  func optionHeldPanelSurvivesTheReleaseWatch() async {
    let fixture = twoAppFixture(front: safari, commandIsHeld: false, heldModifiers: .maskAlternate)
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)

    #expect(fixture.surface.isPresented)
    try? await Task.sleep(for: .milliseconds(50))
    #expect(fixture.surface.isPresented)
    #expect(fixture.surface.dismissCount == 0)
  }

  @Test
  func delayedOptionReleaseCommitsWithoutShowing() async {
    let waiting = waitingPresenter()
    waiting.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)

    #expect(waiting.presenter.pendingShow.isWaiting)
    waiting.presenter.handleOptionRelease()
    await settle()
    #expect(waiting.surface.presentedLists.isEmpty)
    #expect(waiting.log.lines.contains(where: { $0.hasPrefix("committed ") }))
  }

  @Test
  func otherInvocationMovesSelectionWithoutOpeningSecond() {
    let fixture = twoAppFixture(front: safari)
    fixture.presenter.handleHotkey(.forward, deliveryDelay: nil)
    let first = fixture.surface.shownSelections.last
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)

    #expect(fixture.surface.isPresented)
    #expect(fixture.surface.presentedLists.count == 1)
    #expect(fixture.surface.shownSelections.last != first)
  }

  @Test
  func mainPressMovesParallelSelectionTheSameWay() {
    let fixture = twoAppFixture(front: safari)
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)
    let first = fixture.surface.shownSelections.last
    fixture.presenter.handleHotkey(.forward, deliveryDelay: nil)

    #expect(fixture.surface.isPresented)
    #expect(fixture.surface.presentedLists.count == 1)
    #expect(fixture.surface.shownSelections.last != first)
  }

  @Test
  func filteringOtherInvocationHides() {
    let fixture = twoAppFixture(front: safari)
    fixture.presenter.handleHotkey(.forward, deliveryDelay: nil)
    fixture.presenter.switchToFiltering()
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)

    #expect(!fixture.surface.isPresented)
    #expect(fixture.surface.presentedLists.count == 1)
  }

  @Test
  func otherInvocationWithoutMonitorHides() {
    let fixture = twoAppFixture(front: safari, closesOnCommandRelease: false)
    fixture.presenter.handleHotkey(.forward, deliveryDelay: nil)
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)

    #expect(!fixture.surface.isPresented)
    #expect(fixture.surface.presentedLists.count == 1)
  }

  @Test
  func delayedOtherPressKeepsTheFirstPressSettings() async {
    let waiting = waitingPresenter()
    waiting.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)
    waiting.commandHold.isHeld = true
    waiting.presenter.handleHotkey(.forward, deliveryDelay: nil)
    waiting.sleep.open()
    await settle()

    let shown = waiting.surface.presentedLists.last ?? []
    #expect(shown.count == 3)
    #expect(shown.allSatisfy { $0.ownerProcessIdentifier == safari })
    #expect(waiting.surface.shownSelections.count == 1)
    waiting.presenter.handleOptionRelease()
    #expect(!waiting.surface.isPresented)
    #expect(waiting.log.lines.contains(where: { $0.hasPrefix("committed ") }))
  }

  @Test
  func firstListWaitDropsTheOtherPress() async {
    let rows = twoAppRows()
    let fake = HeldGather(answer: WindowListSnapshot(
      items: rows,
      applicationCount: 2,
      gatheringDuration: .milliseconds(12),
      skipped: [],
      droppedWithoutID: 0,
      gatheredAt: .now
    ))
    let fixture = Fixture(
      store: WindowListStore(gather: fake.gather, writeLine: { _ in }),
      commandIsHeld: false,
      heldModifiers: .maskAlternate
    )
    fixture.presenter.keyCommands.frontmostProcessIdentifier = { safari }
    fixture.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)
    await fake.waitUntilCalled()
    fixture.presenter.handleHotkey(.forward, deliveryDelay: nil)
    fake.finish()
    await settle()

    #expect(fixture.surface.presentedLists.count == 1)
    let shown = fixture.surface.presentedLists.last ?? []
    #expect(shown.count == 3)
    #expect(shown.allSatisfy { $0.ownerProcessIdentifier == safari })
  }

  @Test
  func diagnosticLinesNameTheSwitcher() {
    let main = twoAppFixture(front: safari)
    main.presenter.handleHotkey(.forward, deliveryDelay: nil)
    #expect(main.log.lines.contains(where: { $0.hasPrefix("panel shown") && $0.contains("main") }))
    main.presenter.handleCommandRelease()
    #expect(main.log.lines.contains(where: { $0.hasPrefix("committed ") && $0.contains("main") }))

    let parallel = twoAppFixture(front: safari)
    parallel.presenter.handleHotkey(.parallelForward, deliveryDelay: nil)
    #expect(parallel.log.lines.contains(where: { $0.hasPrefix("panel shown") && $0.contains("parallel") }))
    parallel.presenter.modifierFlagsChanged([])
    parallel.presenter.handleOptionRelease()
    #expect(parallel.log.lines.contains(where: { $0.hasPrefix("committed ") && $0.contains("parallel") }))

    let filter = twoAppFixture(front: safari)
    filter.presenter.handleHotkey(.filter, deliveryDelay: nil)
    #expect(filter.log.lines.contains(where: { $0.hasPrefix("panel shown") && $0.contains("main") }))
  }

  // MARK: Private

  private let safari: pid_t = 100
  private let finder: pid_t = 200

  /// Five rows across two owners, with the front application injected so
  /// no window server takes part.
  private func twoAppRows() -> [WindowItem] {
    [
      parallelRow(1, owner: safari, app: "Safari", title: "Front page"),
      parallelRow(2, owner: safari, app: "Safari", title: "Downloads"),
      parallelRow(3, owner: safari, app: "Safari", title: "Reading list"),
      parallelRow(4, owner: finder, app: "Finder", title: "Documents"),
      parallelRow(5, owner: finder, app: "Finder", title: "Desktop"),
    ]
  }

  /// A presenter held at its show delay, so presses and releases land
  /// while the wait is still shut. Both holds start as an Option-held
  /// press finds them: Command up, Option down.
  private func waitingPresenter() -> (
    presenter: PanelPresenter,
    surface: FakeSurface,
    log: DiagnosticsLog,
    sleep: GatedSleep,
    commandHold: CommandHold,
    optionHold: CommandHold
  ) {
    let surface = FakeSurface()
    let log = DiagnosticsLog()
    let clock = SteppingClock(step: .microseconds(4800))
    let sleep = GatedSleep()
    let commandHold = CommandHold(isHeld: false)
    let optionHold = CommandHold(isHeld: true)
    let presenter = PanelPresenter(
      surface: surface,
      store: WindowListStore(fixed: twoAppRows()),
      ownProcessIdentifier: ownProcess,
      now: clock.read,
      writeLine: log.write,
      closesOnCommandRelease: { true },
      commandIsHeld: { [commandHold] in commandHold.read() },
      optionIsHeld: { [optionHold] in optionHold.read() },
      modifierFlags: { .maskAlternate },
      commandWatchInterval: .milliseconds(1),
      keyStatusWatchInterval: .milliseconds(1),
      showDelayMs: 150,
      showDelaySleep: sleep.sleep,
      switcher: FakeWindowSwitcher()
    )
    presenter.keyCommands.frontmostProcessIdentifier = { safari }
    return (presenter, surface, log, sleep, commandHold, optionHold)
  }

  private func twoAppFixture(
    front: pid_t,
    commandIsHeld: Bool = true,
    heldModifiers: CGEventFlags = .maskCommand,
    closesOnCommandRelease: Bool = true
  ) -> Fixture {
    let rows = twoAppRows()
    let fixture = Fixture(
      store: WindowListStore(fixed: rows),
      windows: rows,
      closesOnCommandRelease: closesOnCommandRelease,
      commandIsHeld: commandIsHeld,
      heldModifiers: heldModifiers
    )
    fixture.presenter.keyCommands.frontmostProcessIdentifier = { front }
    return fixture
  }

}
