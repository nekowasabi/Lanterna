import AppKit
@testable import Lanterna
import Testing

@MainActor
struct TonikakuCompatTests {

  // MARK: Internal

  @Test
  func activeMarksEveryRowNotHidden() {
    let unhidden = snapshot().unhidingApplications(when: true)
    #expect(unhidden.items.allSatisfy { !$0.isHidden })
    #expect(unhidden.items.map(\.id) == snapshot().items.map(\.id))
  }

  @Test
  func inactiveKeepsTheHiddenRows() {
    #expect(snapshot().unhidingApplications(when: false).items.map(\.isHidden) == [true, false])
  }

  // MARK: Private

  private func snapshot() -> WindowListSnapshot {
    WindowListSnapshot(
      items: [row(windowID: 1, hidden: true), row(windowID: 2, hidden: false)],
      applicationCount: 2,
      gatheringDuration: .milliseconds(10),
      skipped: [],
      droppedWithoutID: 0,
      gatheredAt: ContinuousClock.now
    )
  }

  private func row(windowID: CGWindowID, hidden: Bool) -> WindowItem {
    WindowItem(
      id: WindowItem.Identifier(windowID: windowID),
      ownerProcessIdentifier: pid_t(windowID),
      appName: "App \(windowID)",
      bundleIdentifier: nil,
      windowTitle: "Window",
      kind: .standard,
      isMinimized: false,
      isHidden: hidden,
      icon: NSImage()
    )
  }

}
