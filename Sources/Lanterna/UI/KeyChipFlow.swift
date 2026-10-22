import SwiftUI

/// Lays a row's key buttons out left to right, wrapping onto further lines
/// when they outgrow the offered width, each line flush with the trailing
/// edge.
///
/// A plain HStack squeezes every button instead, which leaves a row with
/// many keys, such as the digit jumps, as a strip of blank buttons.
struct KeyChipFlow: Layout {

  // MARK: Internal

  var spacing: CGFloat = 8
  var lineSpacing: CGFloat = 6

  /// Splits the chips into lines that fit within `maxWidth`. A chip wider
  /// than the line still takes a line of its own rather than vanishing.
  static func lines(widths: [CGFloat], maxWidth: CGFloat, spacing: CGFloat) -> [Range<Int>] {
    var lines = [Range<Int>]()
    var start = 0
    var used: CGFloat = 0
    for (index, width) in widths.enumerated() {
      if index > start, used + spacing + width > maxWidth {
        lines.append(start ..< index)
        start = index
        used = width
      } else {
        used += (index > start ? spacing : 0) + width
      }
    }
    if start < widths.count {
      lines.append(start ..< widths.count)
    }
    return lines
  }

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
    let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
    let lines = Self.lines(
      widths: sizes.map(\.width),
      maxWidth: proposal.width ?? .infinity,
      spacing: spacing
    )
    let width = lines.lazy.map { lineWidth(sizes[$0]) }.max() ?? 0
    let height = lines.lazy.map { lineHeight(sizes[$0]) }.reduce(0, +)
      + lineSpacing * CGFloat(max(lines.count - 1, 0))
    return CGSize(width: width, height: height)
  }

  func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
    let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
    var y = bounds.minY
    for line in Self.lines(widths: sizes.map(\.width), maxWidth: bounds.width, spacing: spacing) {
      let height = lineHeight(sizes[line])
      var x = bounds.maxX - lineWidth(sizes[line])
      for index in line {
        subviews[index].place(
          at: CGPoint(x: x, y: y + height / 2),
          anchor: .leading,
          proposal: ProposedViewSize(sizes[index])
        )
        x += sizes[index].width + spacing
      }
      y += height + lineSpacing
    }
  }

  // MARK: Private

  private func lineWidth(_ sizes: ArraySlice<CGSize>) -> CGFloat {
    sizes.map(\.width).reduce(0, +) + spacing * CGFloat(max(sizes.count - 1, 0))
  }

  private func lineHeight(_ sizes: ArraySlice<CGSize>) -> CGFloat {
    sizes.map(\.height).max() ?? 0
  }

}
