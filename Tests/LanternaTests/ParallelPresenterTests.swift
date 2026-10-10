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

  // MARK: Private

  private let safari: pid_t = 100
  private let finder: pid_t = 200

  /// Five rows across two owners, with the front application injected so
  /// no window server takes part.
  private func twoAppFixture(front: pid_t, closesOnCommandRelease: Bool = true) -> Fixture {
    let rows = [
      parallelRow(1, owner: safari, app: "Safari", title: "Front page"),
      parallelRow(2, owner: safari, app: "Safari", title: "Downloads"),
      parallelRow(3, owner: safari, app: "Safari", title: "Reading list"),
      parallelRow(4, owner: finder, app: "Finder", title: "Documents"),
      parallelRow(5, owner: finder, app: "Finder", title: "Desktop"),
    ]
    let fixture = Fixture(
      store: WindowListStore(fixed: rows),
      windows: rows,
      closesOnCommandRelease: closesOnCommandRelease
    )
    fixture.presenter.keyCommands.frontmostProcessIdentifier = { front }
    return fixture
  }

}
