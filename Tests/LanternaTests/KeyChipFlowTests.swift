@testable import Lanterna
import Testing

struct KeyChipFlowTests {

  @Test
  func chipsThatFitStayOnOneLine() {
    #expect(KeyChipFlow.lines(widths: [40, 40, 40], maxWidth: 200, spacing: 8) == [0 ..< 3])
  }

  @Test
  func overflowingChipsWrapOntoTheNextLine() {
    // 40 + 8 + 40 + 8 + 40 = 136 fits; the fourth chip would reach 184.
    #expect(KeyChipFlow.lines(widths: [40, 40, 40, 40], maxWidth: 150, spacing: 8) == [0 ..< 3, 3 ..< 4])
  }

  @Test
  func aChipWiderThanTheLineStillGetsItsOwnLine() {
    #expect(KeyChipFlow.lines(widths: [300, 40], maxWidth: 100, spacing: 8) == [0 ..< 1, 1 ..< 2])
  }

  @Test
  func anUnboundedWidthKeepsEveryChipOnOneLine() {
    #expect(KeyChipFlow.lines(widths: Array(repeating: 60, count: 20), maxWidth: .infinity, spacing: 8) == [0 ..< 20])
  }

  @Test
  func noChipsMeansNoLines() {
    #expect(KeyChipFlow.lines(widths: [], maxWidth: 100, spacing: 8).isEmpty)
  }

}
