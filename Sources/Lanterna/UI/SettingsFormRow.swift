import SwiftUI

// MARK: - SettingsFormLabel

/// The label side of a settings control row.
///
/// A heading with an optional note under it, so toggles, pickers, and
/// other labeled controls read alike across tabs.
struct SettingsFormLabel: View {
  init(title: String, caption: String? = nil) {
    self.title = title
    self.caption = caption
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text(title)
      if let caption {
        Text(caption)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  private let title: String
  private let caption: String?
}

// MARK: - View + settingsBackground

extension View {
  /// The background behind grouped settings content.
  ///
  /// The window background rather than the under-page color: the latter
  /// is the mid gray behind document pages, which turned the whole
  /// content area dark in light appearance.
  func settingsBackground() -> some View {
    scrollContentBackground(.hidden)
      .background(Color(nsColor: .windowBackgroundColor))
  }

  /// The sidebar gray, a touch darker than the detail.
  func settingsSidebarBackground() -> some View {
    scrollContentBackground(.hidden)
      .background {
        Color(nsColor: .windowBackgroundColor)
          .overlay(Color.black.opacity(0.04))
      }
  }
}
