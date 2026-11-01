import AppKit

// MARK: - TonikakuCompat

/// Tonikaku parks the apps of inactive workspaces with
/// `NSRunningApplication.hide()`, the same bit Cmd+H sets. While it runs, a
/// hidden application means "on another workspace", so its rows are listed
/// as ordinary rows instead of under the hidden-app mode.
enum TonikakuCompat {
  static let bundleIdentifier = "com.example.tonikaku"

  @MainActor
  static var isRunning: Bool {
    !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
  }
}

extension WindowListSnapshot {
  /// The same pass with every row marked not hidden when `active`.
  func unhidingApplications(when active: Bool) -> WindowListSnapshot {
    guard active else {
      return self
    }
    return WindowListSnapshot(
      items: items.map { $0.isHidden ? $0.settingHidden(false) : $0 },
      applicationCount: applicationCount,
      gatheringDuration: gatheringDuration,
      skipped: skipped,
      droppedWithoutID: droppedWithoutID,
      gatheredAt: gatheredAt,
      spacesUnread: spacesUnread,
      otherSpacesCutShort: otherSpacesCutShort
    )
  }
}
