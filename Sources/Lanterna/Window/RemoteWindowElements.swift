import ApplicationServices
import PrivateAPIs

/// The windows of one application that the accessibility window list leaves
/// out: those on a Space no display is showing.
///
/// The only source of such elements, so listing them and switching to them
/// agree on what exists. Each call probes the application's element ids one
/// by one and costs tens to a couple of hundred milliseconds.
enum RemoteWindowElements {

  // MARK: Internal

  /// Windows found by id, stopping early once `isExpired` answers true.
  ///
  /// A nonexistent id answers an error at once. That is the common case and
  /// says nothing about the application, so it is skipped silently. Untitled
  /// helper windows the accessibility server never exposes are not found.
  static func windows(of pid: pid_t, until isExpired: () -> Bool = { false }) -> [AXUIElement] {
    var prefix = Data()
    withUnsafeBytes(of: pid) { prefix.append(contentsOf: $0) }
    withUnsafeBytes(of: Int32(0)) { prefix.append(contentsOf: $0) }
    withUnsafeBytes(of: Int32(0x636F_636F)) { prefix.append(contentsOf: $0) }

    var found = [AXUIElement]()
    for id in elementIDs {
      if isExpired() {
        break
      }
      var token = prefix
      withUnsafeBytes(of: id) { token.append(contentsOf: $0) }
      guard
        let element = _AXUIElementCreateWithRemoteToken(token as CFData),
        AXUIElementSetMessagingTimeout(element, probeTimeout) == .success,
        isWindow(element)
      else { continue }
      found.append(element)
    }
    return found
  }

  // MARK: Private

  /// Measured: every titled window of another Space answered within this
  /// range, and widening it to 20000 found nothing more.
  private static let elementIDs: Range<UInt64> = 0..<1000
  private static let probeTimeout: Float = 0.1

  private static func isWindow(_ element: AXUIElement) -> Bool {
    var role: CFTypeRef?
    guard
      AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role) == .success,
      role as? String == kAXWindowRole
    else { return false }
    var windowID: CGWindowID = 0
    return _AXUIElementGetWindow(element, &windowID) == .success && windowID != 0
  }

}
