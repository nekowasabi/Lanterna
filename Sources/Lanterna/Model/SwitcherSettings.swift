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

/// One switcher's panel settings, fully resolved.
///
/// Holds the panel-related items alone: the shared appearance, the
/// non-invocation bindings, the exclusions, the hand-arranged order, the
/// manual group names and assignments, and the application-wide settings
/// all stay single. The romaji scope stays shared too: the matcher engine
/// opens once per run, while the fuzzy-match switch lives here.
struct SwitcherSettings: Equatable, Sendable {

  /// The resolved main-switcher defaults: the long-standing behaviour.
  static let mainDefaults = SwitcherSettings(
    windowScope: .allApps,
    displayModes: .defaults,
    resultOrder: .mru,
    groupingMode: .none,
    subgroupPlacements: [:],
    groupCount: 1,
    groupHeadingStyle: .number,
    displayTarget: .primary,
    panelWidth: .standard,
    textScale: .standard,
    showDelayMs: nil,
    hintsMode: .prefix,
    numberJump: false,
    numberReorder: false,
    numberScope: .windows,
    hoverSelect: false,
    scrollSelect: false,
    fuzzyMatchEnabled: true
  )

  var windowScope: WindowScope
  var displayModes: DisplayModes
  var resultOrder: SearchOrdering
  var groupingMode: GroupingMode
  var subgroupPlacements: [DisplaySubgroup: SubgroupPlacement]
  var groupCount: Int
  var groupHeadingStyle: GroupHeadingStyle
  var displayTarget: DisplayTarget
  var panelWidth: PanelWidth
  var textScale: TextScaleLevel
  var showDelayMs: Double?
  var hintsMode: HintsMode
  var numberJump: Bool
  var numberReorder: Bool
  var numberScope: NumberScope
  var hoverSelect: Bool
  var scrollSelect: Bool
  var fuzzyMatchEnabled: Bool

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
      resultOrder: overrides.resultOrder.resolved(with: main.resultOrder),
      groupingMode: overrides.groupingMode.resolved(with: main.groupingMode),
      subgroupPlacements: DisplaySubgroup.drawingOrder.reduce(
        into: [DisplaySubgroup: SubgroupPlacement]()
      ) { placements, subgroup in
        placements[subgroup] = overrides.placement(of: subgroup).resolved(
          with: main.subgroupPlacements[subgroup] ?? .endOfList
        )
      },
      groupCount: overrides.groupCount.resolved(with: main.groupCount),
      groupHeadingStyle: overrides.groupHeadingStyle.resolved(with: main.groupHeadingStyle),
      displayTarget: overrides.displayTarget.resolved(with: main.displayTarget),
      panelWidth: overrides.panelWidth.resolved(with: main.panelWidth),
      textScale: overrides.textScale.resolved(with: main.textScale),
      showDelayMs: overrides.showDelayMs.resolved(with: main.showDelayMs),
      hintsMode: overrides.hintsMode.resolved(with: main.hintsMode),
      numberJump: overrides.numberJump.resolved(with: main.numberJump),
      numberReorder: overrides.numberReorder.resolved(with: main.numberReorder),
      numberScope: overrides.numberScope.resolved(with: main.numberScope),
      hoverSelect: overrides.hoverSelect.resolved(with: main.hoverSelect),
      scrollSelect: overrides.scrollSelect.resolved(with: main.scrollSelect),
      fuzzyMatchEnabled: overrides.fuzzyMatchEnabled.resolved(with: main.fuzzyMatchEnabled)
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
  var resultOrder = FollowOrOwn<SearchOrdering>.follow
  var groupingMode = FollowOrOwn<GroupingMode>.follow
  var otherSpacePlacement = FollowOrOwn<SubgroupPlacement>.follow
  var hiddenAppPlacement = FollowOrOwn<SubgroupPlacement>.follow
  var minimizedPlacement = FollowOrOwn<SubgroupPlacement>.follow
  var fullscreenPlacement = FollowOrOwn<SubgroupPlacement>.follow
  var windowlessAppPlacement = FollowOrOwn<SubgroupPlacement>.follow
  var groupCount = FollowOrOwn<Int>.follow
  var groupHeadingStyle = FollowOrOwn<GroupHeadingStyle>.follow
  var displayTarget = FollowOrOwn<DisplayTarget>.follow
  var panelWidth = FollowOrOwn<PanelWidth>.follow
  var textScale = FollowOrOwn<TextScaleLevel>.follow
  var showDelayMs = FollowOrOwn<Double?>.follow
  var hintsMode = FollowOrOwn<HintsMode>.follow
  var numberJump = FollowOrOwn<Bool>.follow
  var numberReorder = FollowOrOwn<Bool>.follow
  var numberScope = FollowOrOwn<NumberScope>.follow
  var hoverSelect = FollowOrOwn<Bool>.follow
  var scrollSelect = FollowOrOwn<Bool>.follow
  var fuzzyMatchEnabled = FollowOrOwn<Bool>.follow
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
