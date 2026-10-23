import Foundation

// MARK: - SingleCandidateFocus

/// When a typed filter has narrowed the list to one row.
///
/// The decision is a value so the wait can be tested apart from the
/// panel, and so a refresh that did not change the query cannot look
/// like a new narrowing. Arming is the only path into the wait. A list
/// that was already one row, an empty query, and a recovery from no
/// match never arm.
enum SingleCandidateFocus {

  /// What one narrowing looks like to the decision.
  struct Snapshot: Equatable, Sendable {
    var enabled: Bool
    var filtering: Bool
    var query: String
    var count: Int
    var chosen: WindowItem.Identifier?
  }

  /// What to do with the wait after one narrowing.
  enum Decision: Equatable, Sendable {
    case arm
    case cancel
    case leave
  }

  /// How long the one row has to remain the one row.
  ///
  /// Long enough for the next edit of a fast burst to widen the list
  /// again, short enough that a pause reads as a choice.
  static let settle = Duration.milliseconds(180)

  /// Arms only when a non-empty filter just moved from several rows to
  /// one. A later edit that is still one row restarts the wait. Anything
  /// else that is no longer one row cancels. A refresh that did not
  /// change the query leaves an armed wait alone and does not start one.
  static func decision(
    queryChanged: Bool,
    previousCount: Int,
    armed: Bool,
    next: Snapshot
  ) -> Decision {
    let oneRow = next.enabled
      && next.filtering
      && !next.query.isEmpty
      && next.count == 1
      && next.chosen != nil
    guard oneRow else { return .cancel }
    if queryChanged, previousCount > 1 || armed {
      return .arm
    }
    return .leave
  }

}

// MARK: - PendingSingleCandidateFocus

/// The wait for one armed narrowing, and nothing else.
///
/// One generation at a time. A new arm or a cancel retires the wait
/// that is already sleeping, so a burst that leaves one row and comes
/// back, or that widens, cannot focus twice and cannot focus late.
@MainActor
final class PendingSingleCandidateFocus {

  // MARK: Internal

  /// How long an arm waits. Tests replace it. Production sleeps.
  var sleep: @MainActor (Duration) async -> Void = { duration in
    try? await Task.sleep(for: duration)
  }

  /// The row to take when the wait elapses on the same arm.
  var onFire: (@MainActor (WindowItem.Identifier) -> Void)?

  /// Retires any wait. Safe when none is armed.
  func cancel() {
    retire()
  }

  /// Applies one narrowing to the wait.
  func note(
    queryChanged: Bool,
    previousCount: Int,
    next: SingleCandidateFocus.Snapshot
  ) {
    switch SingleCandidateFocus.decision(
      queryChanged: queryChanged,
      previousCount: previousCount,
      armed: armed,
      next: next
    ) {
    case .arm:
      guard let chosen = next.chosen else { return }
      arm(chosen)

    case .cancel:
      cancel()

    case .leave:
      break
    }
  }

  // MARK: Private

  private var generation = 0
  private var armed = false
  private var timer: Task<Void, Never>?

  private func retire() {
    generation += 1
    armed = false
    timer?.cancel()
    timer = nil
  }

  private func arm(_ id: WindowItem.Identifier) {
    retire()
    generation += 1
    let seen = generation
    armed = true
    timer = Task { [weak self] in
      await self?.sleep(SingleCandidateFocus.settle)
      guard let self, !Task.isCancelled, generation == seen else { return }
      armed = false
      timer = nil
      generation += 1
      onFire?(id)
    }
  }

}
