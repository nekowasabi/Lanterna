import SwiftUI

// MARK: - FollowPicker

/// One parallel-switcher row: its own value or following the main
/// switcher. The follow choice always reads first, so leaving every row
/// there keeps the parallel switcher tracking the main one.
private struct FollowPicker<Value: Equatable & Sendable>: View {

  // MARK: Internal

  let title: String
  let caption: String?
  let choices: [(String, Value)]

  @Binding var selection: FollowOrOwn<Value>

  var body: some View {
    Picker(selection: index) {
      Text("Same as main switcher").tag(-1)
      ForEach(choices.indices, id: \.self) { offset in
        Text(choices[offset].0).tag(offset)
      }
    } label: {
      SettingsFormLabel(title: title, caption: caption)
    }
    .pickerStyle(.menu)
  }

  // MARK: Private

  /// The choice as a tag: follow reads as the one before the first value.
  private var index: Binding<Int> {
    Binding(
      get: {
        guard case .own(let value) = selection else { return -1 }
        return choices.firstIndex(where: { $0.1 == value }) ?? -1
      },
      set: { offset in
        selection = offset < 0 ? .follow : .own(choices[offset].1)
      }
    )
  }

}

// MARK: - SettingsParallelView

/// The Parallel tab: the second switcher's own panel settings.
///
/// Every row either follows the main switcher or carries its own value.
/// Only the window scope differs out of the box: the parallel switcher
/// lists the front application's windows alone, everything else follows.
struct SettingsParallelView: View {

  // MARK: Internal

  @Binding var values: SettingsValues

  var body: some View {
    Form {
      Section("Parallel switcher") {
        Toggle(isOn: $values.parallelOverrides.isEnabled) {
          SettingsFormLabel(
            title: "Parallel switcher",
            caption: "Answer the parallel invocations with a second panel. "
              + "Off hands those keys back to the front application."
          )
        }
        FollowPicker(
          title: "Show windows of",
          caption: "List every app's windows, or only the active app's when the parallel panel opens.",
          choices: [("All apps", .allApps), ("Front app", .frontApp)],
          selection: $values.parallelOverrides.windowScope
        )
      }
      Section("Window types") {
        FollowPicker(
          title: "Windows on other spaces",
          caption: "Windows living on another Space, for the parallel panel.",
          choices: Self.modes,
          selection: $values.parallelOverrides.otherSpaceMode
        )
        FollowPicker(
          title: "Windows of hidden apps",
          caption: "Windows of hidden applications, for the parallel panel.",
          choices: Self.modes,
          selection: $values.parallelOverrides.hiddenAppMode
        )
        FollowPicker(
          title: "Minimized windows",
          caption: "Windows folded into the Dock, for the parallel panel.",
          choices: Self.modes,
          selection: $values.parallelOverrides.minimizedMode
        )
        FollowPicker(
          title: "Fullscreen windows",
          caption: "Windows filling their own Space, for the parallel panel.",
          choices: Self.modes,
          selection: $values.parallelOverrides.fullscreenMode
        )
        FollowPicker(
          title: "Apps without windows",
          caption: "Running apps with no open window, for the parallel panel.",
          choices: Self.modes,
          selection: $values.parallelOverrides.windowlessAppMode
        )
      }
      Section("Search") {
        FollowPicker(
          title: "Fuzzy matching",
          caption: "Match subsequence queries as well as substrings, for the parallel panel.",
          choices: [("On", true), ("Off", false)],
          selection: $values.parallelOverrides.fuzzyMatchEnabled
        )
        FollowPicker(
          title: "Result order",
          caption: "Recent use first, or best match first, for the parallel panel.",
          choices: [("Recent use first", SearchOrdering.mru), ("Best match first", SearchOrdering.score)],
          selection: $values.parallelOverrides.resultOrder
        )
      }
      Section("Grouping") {
        FollowPicker(
          title: "Group windows",
          caption: "Keep one list, or group rows the way the Groups tab lays out, for the parallel panel.",
          choices: [
            ("Don't group", GroupingMode.none),
            ("By Space", GroupingMode.bySpace),
            ("Manually", GroupingMode.manual),
          ],
          selection: $values.parallelOverrides.groupingMode
        )
        FollowPicker(
          title: "Manual group count",
          caption: "How many manual groups there are, for the parallel panel.",
          choices: (1 ... 9).map { ("\($0)", $0) },
          selection: $values.parallelOverrides.groupCount
        )
        FollowPicker(
          title: "Group headings",
          caption: "What a manual group heading says, for the parallel panel.",
          choices: [
            ("Number", GroupHeadingStyle.number),
            ("Name", GroupHeadingStyle.name),
            ("App names", GroupHeadingStyle.appNames),
          ],
          selection: $values.parallelOverrides.groupHeadingStyle
        )
        FollowPicker(
          title: "Other-Space placement",
          caption: "Where the windows-on-other-spaces section goes when grouped, for the parallel panel.",
          choices: Self.placements,
          selection: $values.parallelOverrides.otherSpacePlacement
        )
        FollowPicker(
          title: "Hidden-app placement",
          caption: "Where the hidden-apps section goes when grouped, for the parallel panel.",
          choices: Self.placements,
          selection: $values.parallelOverrides.hiddenAppPlacement
        )
        FollowPicker(
          title: "Minimized placement",
          caption: "Where the minimized section goes when grouped, for the parallel panel.",
          choices: Self.placements,
          selection: $values.parallelOverrides.minimizedPlacement
        )
        FollowPicker(
          title: "Fullscreen placement",
          caption: "Where the fullscreen section goes when grouped, for the parallel panel.",
          choices: Self.placements,
          selection: $values.parallelOverrides.fullscreenPlacement
        )
        FollowPicker(
          title: "Windowless placement",
          caption: "Where the apps-without-windows section goes when grouped, for the parallel panel.",
          choices: Self.placements,
          selection: $values.parallelOverrides.windowlessAppPlacement
        )
      }
      Section("Panel") {
        FollowPicker(
          title: "Display",
          caption: "Which display the parallel panel opens on.",
          choices: [
            ("Menu-bar display", DisplayTarget.primary),
            ("Cursor display", DisplayTarget.cursor),
            ("Focused window display", DisplayTarget.frontWindow),
            ("Every display", DisplayTarget.all),
          ],
          selection: $values.parallelOverrides.displayTarget
        )
        FollowPicker(
          title: "Width",
          caption: "How wide the parallel panel reads.",
          choices: [
            ("Narrower", PanelWidth.narrowMinus),
            ("Narrow", PanelWidth.narrow),
            ("Standard", PanelWidth.standard),
            ("Wide", PanelWidth.wide),
            ("Wider", PanelWidth.widePlus),
          ],
          selection: $values.parallelOverrides.panelWidth
        )
        FollowPicker(
          title: "Text size",
          caption: "How large the parallel panel draws text and icons.",
          choices: [
            ("Smaller", TextScaleLevel.small),
            ("Small", TextScaleLevel.smallMedium),
            ("Standard", TextScaleLevel.standard),
            ("Large", TextScaleLevel.largeMedium),
            ("Larger", TextScaleLevel.large),
          ],
          selection: $values.parallelOverrides.textScale
        )
        FollowPicker(
          title: "Row hints",
          caption: "How the left edge of each parallel row reads.",
          choices: [
            ("Prefix hints", HintsMode.prefix),
            ("Row numbers", HintsMode.numbers),
            ("Neither", HintsMode.neither),
          ],
          selection: $values.parallelOverrides.hintsMode
        )
        FollowPicker(
          title: "Show delay",
          caption: "How long a parallel press waits before the panel appears. "
            + "Off shows at once on its own, even where the main switcher waits.",
          choices: [("Off", nil), ("150 ms", 150.0), ("300 ms", 300.0), ("500 ms", 500.0), ("1000 ms", 1000.0)],
          selection: $values.parallelOverrides.showDelayMs
        )
      }
      Section("Rows") {
        FollowPicker(
          title: "Jump to row number",
          caption: "Hold a modifier and press a row number to jump there, in the parallel panel.",
          choices: [("On", true), ("Off", false)],
          selection: $values.parallelOverrides.numberJump
        )
        FollowPicker(
          title: "Reorder rows",
          caption: "Move the chosen row by key in grouped lists, in the parallel panel.",
          choices: [("On", true), ("Off", false)],
          selection: $values.parallelOverrides.numberReorder
        )
        FollowPicker(
          title: "Numbered rows",
          caption: "Which rows row numbers cover, in the parallel panel.",
          choices: [("Window rows", NumberScope.windows), ("Every row", NumberScope.allRows)],
          selection: $values.parallelOverrides.numberScope
        )
        FollowPicker(
          title: "Hover to select",
          caption: "Move the choice with the pointer, in the parallel panel.",
          choices: [("On", true), ("Off", false)],
          selection: $values.parallelOverrides.hoverSelect
        )
        FollowPicker(
          title: "Scroll to select",
          caption: "Move the choice with scrolling, in the parallel panel.",
          choices: [("On", true), ("Off", false)],
          selection: $values.parallelOverrides.scrollSelect
        )
      }
    }
    .formStyle(.grouped)
    .settingsBackground()
  }

  // MARK: Private

  /// The shared display-mode choices, in file order.
  private static let modes: [(String, DisplayMode)] = [
    ("Show", .show),
    ("Hide", .hide),
    ("Separate at bottom", .separateAtBottom),
  ]

  /// The shared parked-section choices, in file order.
  private static let placements: [(String, SubgroupPlacement)] = [
    ("End of list", .endOfList),
    ("Within each group", .withinGroup),
  ]

}
