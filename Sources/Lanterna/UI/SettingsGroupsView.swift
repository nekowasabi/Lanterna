import SwiftUI

// MARK: - SettingsGroupsView

/// The Groups tab: whether the list groups its rows, and the manual
/// groups when it groups by hand.
///
/// Grouping off shows the one choice and nothing else. Where each kind
/// of parked section goes once grouped lives in the Switchers tab, per
/// switcher.
struct SettingsGroupsView: View {

  @Binding var values: SettingsValues

  var body: some View {
    Form {
      Section("Grouping") {
        Picker(selection: $values.grouping.mode) {
          Text("Don't group").tag(GroupingMode.none)
          Text("By Space").tag(GroupingMode.bySpace)
          Text("Manually").tag(GroupingMode.manual)
        } label: {
          SettingsFormLabel(
            title: "Group windows",
            caption: "Keep one list, group rows by the Space they live on, or group apps the way you assign "
              + "them below."
          )
        }
        .pickerStyle(.menu)
        if values.grouping.mode == .manual {
          SettingsManualGroupRows(grouping: $values.grouping)
        }
      }
      if values.grouping.mode == .manual {
        SettingsManualGroupSections(grouping: $values.grouping)
      }
    }
    .formStyle(.grouped)
    .settingsBackground()
  }

}
