// MARK: - QueryText

/// The query as a string with an insertion point.
///
/// The insertion point is counted in characters standing before it, so
/// combining marks and emoji stay whole: moving and deleting by character
/// never splits what the eye reads as one. Every operation below keeps the
/// point within the string, so there is no invalid state to defend
/// against at the call sites.
struct QueryText: Equatable, Sendable {

  // MARK: Internal

  /// The narrowed string.
  var text = ""
  /// How many characters stand before the insertion point.
  /// Always within `0...text.count`.
  var cursor = 0

  /// Inserts the string at the insertion point, moving the point past
  /// what was inserted. An empty string changes nothing.
  mutating func insert(_ string: String) {
    guard !string.isEmpty else { return }
    text.insert(contentsOf: string, at: index(of: cursor))
    cursor += string.count
  }

  /// Applies one edit, answering whether the string changed. Moving the
  /// point alone never counts as a change, so callers redraw the list
  /// only on `true`.
  mutating func apply(_ edit: QueryEdit) -> Bool {
    switch edit {
    case .moveLeft:
      guard cursor > 0 else { return false }
      cursor -= 1
      return false

    case .moveRight:
      guard cursor < text.count else { return false }
      cursor += 1
      return false

    case .moveToStart:
      cursor = 0
      return false

    case .moveToEnd:
      cursor = text.count
      return false

    case .deleteBackward:
      guard cursor > 0 else { return false }
      remove(range: (cursor - 1) ..< cursor)
      cursor -= 1
      return true

    case .deleteForward:
      guard cursor < text.count else { return false }
      remove(range: cursor ..< (cursor + 1))
      return true

    case .deleteWordBackward:
      let start = wordStart(before: cursor)
      guard start < cursor else { return false }
      remove(range: start ..< cursor)
      cursor = start
      return true

    case .deleteToStart:
      guard cursor > 0 else { return false }
      remove(range: 0 ..< cursor)
      cursor = 0
      return true

    case .deleteToEnd:
      guard cursor < text.count else { return false }
      remove(range: cursor ..< text.count)
      return true
    }
  }

  // MARK: Private

  /// Whether the character takes part in a word: letters and numbers,
  /// in any script, so kana and kanji count while spaces and symbols
  /// divide.
  private func isWordCharacter(_ character: Character) -> Bool {
    character.isLetter || character.isNumber
  }

  /// Where the word before the offset starts: past the dividers, then
  /// past the word characters. Stops at the string start, and the
  /// offset itself when nothing before it is a word.
  private func wordStart(before offset: Int) -> Int {
    var start = offset
    while start > 0, !isWordCharacter(character(at: start - 1)) {
      start -= 1
    }
    while start > 0, isWordCharacter(character(at: start - 1)) {
      start -= 1
    }
    return start
  }

  private func character(at offset: Int) -> Character {
    text[index(of: offset)]
  }

  private func index(of offset: Int) -> String.Index {
    text.index(text.startIndex, offsetBy: offset)
  }

  private mutating func remove(range: Range<Int>) {
    text.removeSubrange(index(of: range.lowerBound) ..< index(of: range.upperBound))
  }

}

// MARK: - QueryEdit

/// One cursor or deletion step, matching one bound key each.
enum QueryEdit: Equatable, Sendable {
  case moveLeft
  case moveRight
  case moveToStart
  case moveToEnd
  case deleteBackward
  case deleteForward
  case deleteWordBackward
  case deleteToStart
  case deleteToEnd
}
