import AppKit
import Carbon.HIToolbox
@testable import Lanterna
import Testing

// MARK: - ParkedSleep

/// A sleep the auto-focus wait can be parked on, then released by the test.
@MainActor
private final class ParkedSleep {

  // MARK: Internal

  private(set) var durations = [Duration]()

  func sleep(_ duration: Duration) async {
    durations.append(duration)
    await withCheckedContinuation { waiters.append($0) }
  }

  func resumeAll() {
    let parked = waiters
    waiters = []
    for waiter in parked {
      waiter.resume()
    }
  }

  // MARK: Private

  private var waiters = [CheckedContinuation<Void, Never>]()

}

@MainActor
private func candidateRow(appName: String, windowTitle: String, windowID: CGWindowID) -> WindowItem {
  WindowItem(
    id: WindowItem.Identifier(windowID: windowID),
    ownerProcessIdentifier: 0,
    appName: appName,
    bundleIdentifier: nil,
    windowTitle: windowTitle,
    kind: .standard,
    isMinimized: false,
    icon: NSImage(size: NSSize(width: 1, height: 1))
  )
}

@MainActor
private func letter(_ character: Character) -> PanelKeystroke {
  let code: Int32 =
    switch character {
    case "m": kVK_ANSI_M
    case "a": kVK_ANSI_A
    case "i": kVK_ANSI_I
    case "l": kVK_ANSI_L
    case "x": kVK_ANSI_X
    default: kVK_ANSI_M
    }
  return PanelKeystroke(
    keyCode: UInt16(code),
    modifiers: [],
    isARepeat: false,
    characters: String(character)
  )
}

@MainActor
private func type(_ text: String, on presenter: PanelPresenter) {
  for character in text {
    #expect(presenter.handleKeyStroke(letter(character)) == .absorbed)
  }
}

/// Lets a task that has reached the parked sleep run after it is released.
private func settle() async {
  for _ in 0 ..< 20 {
    await Task.yield()
  }
}

@MainActor
private func openFiltering(_ windows: [WindowItem], sleep: ParkedSleep, enabled: Bool = true) -> Fixture {
  let fixture = Fixture(store: WindowListStore(fixed: windows), windows: windows)
  fixture.presenter.singleCandidateSleep = { duration in
    await sleep.sleep(duration)
  }
  fixture.presenter.autoFocusSingleCandidate = enabled
  fixture.presenter.handleHotkey(.filter, deliveryDelay: nil)
  return fixture
}

// MARK: - AutoFocusSingleCandidateTests

/// Focusing the one row a typed filter narrowed to.
@MainActor
struct AutoFocusSingleCandidateTests {

  // MARK: Internal

  @Test
  func typingDownToOneCandidateActivatesIt() async {
    let sleep = ParkedSleep()
    let fixture = openFiltering([mail, messages], sleep: sleep)
    type("mai", on: fixture.presenter)
    await settle()
    #expect(sleep.durations == [SingleCandidateFocus.settle])
    sleep.resumeAll()
    await settle()
    #expect(fixture.switcher.targets.count == 1)
    #expect(fixture.switcher.targets.first?.appName == "Mail")
    #expect(!fixture.surface.isPresented)
  }

  @Test
  func aBurstThatWidensAgainDoesNotActivate() async {
    let sleep = ParkedSleep()
    let fixture = openFiltering([mail, messages], sleep: sleep)
    type("mai", on: fixture.presenter)
    await settle()
    let delete = PanelKeystroke(keyCode: UInt16(kVK_Delete), modifiers: [], isARepeat: false)
    #expect(fixture.presenter.handleKeyStroke(delete) == .absorbed)
    sleep.resumeAll()
    await settle()
    #expect(fixture.switcher.targets.isEmpty)
    #expect(fixture.surface.isPresented)
    #expect(fixture.surface.updatedLists.last?.count == 2)
  }

  @Test
  func anAlreadySingleListDoesNotActivate() async {
    let sleep = ParkedSleep()
    let fixture = openFiltering([mail], sleep: sleep)
    await settle()
    sleep.resumeAll()
    await settle()
    #expect(sleep.durations.isEmpty)
    #expect(fixture.switcher.targets.isEmpty)
    #expect(fixture.surface.isPresented)
  }

  @Test
  func typingThatKeepsTheOnlyRowDoesNotActivate() async {
    let sleep = ParkedSleep()
    let fixture = openFiltering([mail], sleep: sleep)
    type("m", on: fixture.presenter)
    await settle()
    sleep.resumeAll()
    await settle()
    #expect(sleep.durations.isEmpty)
    #expect(fixture.switcher.targets.isEmpty)
    #expect(fixture.surface.isPresented)
  }

  @Test
  func anEmptyQueryDoesNotActivate() async {
    let sleep = ParkedSleep()
    let fixture = openFiltering([mail, messages], sleep: sleep)
    await settle()
    sleep.resumeAll()
    await settle()
    #expect(sleep.durations.isEmpty)
    #expect(fixture.switcher.targets.isEmpty)
    #expect(fixture.surface.isPresented)
    #expect(fixture.surface.presentedLists.last?.count == 2)
  }

  @Test
  func clearingBeforeTheWaitDoesNotActivate() async {
    let sleep = ParkedSleep()
    let fixture = openFiltering([mail, messages], sleep: sleep)
    type("mai", on: fixture.presenter)
    await settle()
    let escape = PanelKeystroke(keyCode: UInt16(kVK_Escape), modifiers: [], isARepeat: false)
    #expect(fixture.presenter.handleKeyStroke(escape) == .absorbed)
    sleep.resumeAll()
    await settle()
    #expect(fixture.switcher.targets.isEmpty)
    #expect(fixture.surface.isPresented)
    #expect(fixture.surface.updatedLists.last?.count == 2)
  }

  @Test
  func theSettingOffDoesNotActivate() async {
    let sleep = ParkedSleep()
    let fixture = openFiltering([mail, messages], sleep: sleep, enabled: false)
    type("mai", on: fixture.presenter)
    await settle()
    sleep.resumeAll()
    await settle()
    #expect(sleep.durations.isEmpty)
    #expect(fixture.switcher.targets.isEmpty)
    #expect(fixture.surface.isPresented)
  }

  @Test
  func activatingTwiceDoesNotSwitchTwice() async {
    let sleep = ParkedSleep()
    let fixture = openFiltering([mail, messages], sleep: sleep)
    type("mai", on: fixture.presenter)
    await settle()
    sleep.resumeAll()
    await settle()
    sleep.resumeAll()
    await settle()
    _ = fixture.presenter.handleKeyStroke(
      PanelKeystroke(keyCode: UInt16(kVK_Return), modifiers: [], isARepeat: false, characters: "\r")
    )
    #expect(fixture.switcher.targets.count == 1)
    #expect(fixture.switcher.targets.first?.appName == "Mail")
  }

  @Test
  func recoveringFromNoMatchDoesNotActivate() async {
    let sleep = ParkedSleep()
    let fixture = openFiltering([mail, messages], sleep: sleep)
    type("mailx", on: fixture.presenter)
    await settle()
    let delete = PanelKeystroke(keyCode: UInt16(kVK_Delete), modifiers: [], isARepeat: false)
    #expect(fixture.presenter.handleKeyStroke(delete) == .absorbed)
    await settle()
    sleep.resumeAll()
    await settle()
    #expect(fixture.switcher.targets.isEmpty)
    #expect(fixture.surface.isPresented)
  }

  @Test
  func absentConfigMeansOn() throws {
    let decoded = try #require(decode("{\"version\": 1}").successValue)
    #expect(decoded.config.autoFocusSingleCandidate == nil)
    let values = SettingsValues.effective(from: decoded.config)
    #expect(values.autoFocusSingleCandidate == true)
    let options = AppConfiguration.effectiveOptions(file: decoded.config, cli: LaunchArguments.Options())
    #expect(options.autoFocusSingleCandidate == true)
  }

  @Test
  func falseConfigRoundTrips() throws {
    var values = SettingsValues.defaults
    values.autoFocusSingleCandidate = false
    let config = values.configuration(version: 1, sampleCount: nil, stopMonitorEverySeconds: nil)
    #expect(config.autoFocusSingleCandidate == false)
    let text = try #require(String(bytes: AppConfiguration.encode(config), encoding: .utf8))
    #expect(text.contains("\"autoFocusSingleCandidate\": false"))
    let decoded = try #require(decode(text).successValue)
    #expect(decoded.config.autoFocusSingleCandidate == false)
    #expect(SettingsValues.effective(from: decoded.config).autoFocusSingleCandidate == false)
    #expect(
      decode("{\"version\": 1, \"autoFocusSingleCandidate\": \"yes\"}").failureValue
        == .invalidValue(key: "autoFocusSingleCandidate")
    )
    #expect(
      decode("{\"version\": 1, \"autoFocusSingleCandidate\": 1}").failureValue
        == .invalidValue(key: "autoFocusSingleCandidate")
    )
  }

  // MARK: Private

  private let mail = candidateRow(appName: "Mail", windowTitle: "Inbox", windowID: 1)
  private let messages = candidateRow(appName: "Messages", windowTitle: "Chats", windowID: 2)

  private func decode(_ text: String) -> Result<DecodedConfiguration, ConfigDecodeError> {
    AppConfiguration.decode(Data(text.utf8))
  }

}
