import Foundation

// MARK: - SwitcherIdentity

/// Which switcher opened an appearance: the main one or the parallel one.
///
/// Carried by invocations and kept per appearance, so each showing reads
/// its own switcher's settings and the diagnostics name it.
enum SwitcherIdentity: Equatable, Sendable {
  case main
  case parallel

  // MARK: Internal

  /// The word diagnostics lines name it by.
  var diagnosticsName: String {
    switch self {
    case .main: "main"
    case .parallel: "parallel"
    }
  }
}

// MARK: - FollowOrOwn

/// One parallel-switcher item: a value of its own, or following the main
/// switcher.
///
/// The file spells following as `"inherit"`. Decoding normalizes an absent
/// key to the item's default elsewhere, so this only ever carries what was
/// spelled.
enum FollowOrOwn<Value: Equatable & Sendable>: Equatable, Sendable {
  case follow
  case own(Value)
}

// MARK: - SwitcherSettings

/// One switcher's list settings, fully resolved.
///
/// Holds what decides which windows a list carries and where the parked
/// kinds go: the window scope, the display modes, and the placements of
/// the parked sections. Everything else stays shared by both switchers:
/// the ordering, the fuzzy match, how the list groups, the panel's look
/// and place, the show delay, the in-panel gestures, and the
/// application-wide settings.
struct SwitcherSettings: Equatable, Sendable {

  /// The resolved main-switcher defaults: the long-standing behaviour.
  static let mainDefaults = SwitcherSettings(
    windowScope: .allApps,
    displayModes: .defaults,
    subgroupPlacements: [:]
  )

  var windowScope: WindowScope
  var displayModes: DisplayModes
  var subgroupPlacements: [DisplaySubgroup: SubgroupPlacement]

  /// The parallel switcher resolved over a main one: each following item
  /// takes the main value, each owned item its own.
  static func parallel(main: SwitcherSettings, overrides: ParallelOverrides) -> SwitcherSettings {
    SwitcherSettings(
      windowScope: overrides.windowScope.resolved(with: main.windowScope),
      displayModes: DisplayModes(
        otherSpace: overrides.otherSpaceMode.resolved(with: main.displayModes.otherSpace),
        hiddenApp: overrides.hiddenAppMode.resolved(with: main.displayModes.hiddenApp),
        minimized: overrides.minimizedMode.resolved(with: main.displayModes.minimized),
        fullscreen: overrides.fullscreenMode.resolved(with: main.displayModes.fullscreen),
        windowlessApp: overrides.windowlessAppMode.resolved(with: main.displayModes.windowlessApp)
      ),
      subgroupPlacements: DisplaySubgroup.drawingOrder.reduce(
        into: [DisplaySubgroup: SubgroupPlacement]()
      ) { placements, subgroup in
        placements[subgroup] = overrides.placement(of: subgroup).resolved(
          with: main.subgroupPlacements[subgroup] ?? .endOfList
        )
      }
    )
  }

}

// MARK: - ParallelOverrides

/// What the parallel switcher spells beside the main one.
///
/// Each item either follows the main switcher or carries its own value.
/// The window scope alone defaults to owning the front application; every
/// other item defaults to following. The switch answers whether the
/// parallel invocations reach the panel at all, and defaults to on.
struct ParallelOverrides: Equatable, Sendable {

  static let defaults = ParallelOverrides(
    windowScope: .own(.frontApp),
    isEnabled: true
  )

  var windowScope = FollowOrOwn<WindowScope>.own(.frontApp)
  var otherSpaceMode = FollowOrOwn<DisplayMode>.follow
  var hiddenAppMode = FollowOrOwn<DisplayMode>.follow
  var minimizedMode = FollowOrOwn<DisplayMode>.follow
  var fullscreenMode = FollowOrOwn<DisplayMode>.follow
  var windowlessAppMode = FollowOrOwn<DisplayMode>.follow
  var otherSpacePlacement = FollowOrOwn<SubgroupPlacement>.follow
  var hiddenAppPlacement = FollowOrOwn<SubgroupPlacement>.follow
  var minimizedPlacement = FollowOrOwn<SubgroupPlacement>.follow
  var fullscreenPlacement = FollowOrOwn<SubgroupPlacement>.follow
  var windowlessAppPlacement = FollowOrOwn<SubgroupPlacement>.follow
  var isEnabled = true

  /// The placement override behind one subgroup.
  func placement(of subgroup: DisplaySubgroup) -> FollowOrOwn<SubgroupPlacement> {
    switch subgroup {
    case .otherSpace: otherSpacePlacement
    case .hiddenApp: hiddenAppPlacement
    case .minimized: minimizedPlacement
    case .fullscreen: fullscreenPlacement
    case .windowlessApp: windowlessAppPlacement
    }
  }

}

// MARK: - FollowOrOwn + Resolution

extension FollowOrOwn {

  /// The owned value, or the main value when following.
  func resolved(with main: Value) -> Value {
    switch self {
    case .follow: main
    case .own(let value): value
    }
  }

}
