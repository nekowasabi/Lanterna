import Foundation
import Logging

/// One optional key at a time, split out when the decoding file reached
/// the file-length limit. The shape of the file stays in `AppConfiguration`;
/// everything that reads a single key lives here.
extension AppConfiguration {

  // MARK: Internal

  /// Keys the file may still hold from earlier builds. Their values are
  /// never looked at, so whatever they hold keeps the rest of the file in
  /// force.
  static let deprecatedKeys = ["logLevel"]

  /// Resolves the lenient sections over an otherwise valid file.
  ///
  /// The keybindings section is lenient where the rest of the file is
  /// strict: bad entries fall back per item with diagnostics, while a
  /// section that is not an object at all invalidates the whole file
  /// like any other bad value. Declaration order comes from the file
  /// text, because JSON objects carry no order of their own. The text
  /// scale is lenient the same way on its own: a present but invalid
  /// value falls back to standard with a note.
  /// The section keys holding panel settings rather than shared ones.
  static let switcherPanelKeys: Set = [
    "windowScope",
    "otherSpaceMode",
    "hiddenAppMode",
    "minimizedMode",
    "fullscreenMode",
    "windowlessAppMode",
    "resultOrder",
    "grouping",
    "groupCount",
    "groupHeadingStyle",
    "otherSpacePlacement",
    "hiddenAppPlacement",
    "minimizedPlacement",
    "fullscreenPlacement",
    "windowlessAppPlacement",
    "displayTarget",
    "panelWidth",
    "textScale",
    "showDelayMs",
    "hintsMode",
    "numberJump",
    "numberReorder",
    "numberScope",
    "hoverSelect",
    "scrollSelect",
    "fuzzyMatchEnabled",
  ]

  /// Every key a switcher section takes: the whole file's keys but the
  /// version and the section itself. Anything else fails the file, like
  /// any other unknown key.
  static let switcherSectionKeys: Set<String> = AppConfiguration.knownKeys.subtracting([
    "version",
    "switchers",
  ])

  /// Reads the on-off and channel keys together, so the assembly stays small.
  static func checkedSwitches(
    _ dict: [String: Any],
    into config: inout ValidConfiguration
  ) -> Result<Void, ConfigDecodeError> {
    switch checkedOptionalBool(dict, key: "saveLogsToDisk") {
    case .success(let found):
      config.saveLogsToDisk = found
    case .failure(let error):
      return .failure(error)
    }
    switch checkedOptionalBool(dict, key: "launchAtLogin") {
    case .success(let found):
      config.launchAtLogin = found
    case .failure(let error):
      return .failure(error)
    }
    switch checkedOptionalBool(dict, key: "updateCheckEnabled") {
    case .success(let found):
      config.updateCheckEnabled = found
    case .failure(let error):
      return .failure(error)
    }
    switch checkedOptionalBool(dict, key: "hoverSelect") {
    case .success(let found):
      config.hoverSelect = found
    case .failure(let error):
      return .failure(error)
    }
    switch checkedOptionalBool(dict, key: "scrollSelect") {
    case .success(let found):
      config.scrollSelect = found
    case .failure(let error):
      return .failure(error)
    }
    switch checkedOptionalBool(dict, key: "numberJump") {
    case .success(let found):
      config.numberJump = found
    case .failure(let error):
      return .failure(error)
    }
    switch checkedOptionalBool(dict, key: "numberReorder") {
    case .success(let found):
      config.numberReorder = found
    case .failure(let error):
      return .failure(error)
    }
    switch checkedOptionalChannel(dict, key: "updateChannel") {
    case .success(let found):
      config.updateChannel = found
    case .failure(let error):
      return .failure(error)
    }
    return .success(())
  }

  /// Reads one optional integer key with its lower bound.
  static func checkedOptionalInt(
    _ dict: [String: Any],
    key: String,
    minimum: Int
  ) -> Result<Int?, ConfigDecodeError> {
    guard let rawValue = dict[key] else { return .success(nil) }
    guard let value = jsonInt(rawValue), value >= minimum else {
      return .failure(.invalidValue(key: key))
    }
    return .success(value)
  }

  /// Reads the count keys together, so `decode` stays small.
  static func checkedCountOptions(_ dict: [String: Any]) -> Result<
    (Int?, Int?),
    ConfigDecodeError
  > {
    let sampleCount: Int?
    switch checkedOptionalInt(dict, key: "sampleCount", minimum: 0) {
    case .success(let found):
      sampleCount = found
    case .failure(let error):
      return .failure(error)
    }
    let stopMonitorEvery: Int?
    switch checkedOptionalInt(dict, key: "stopMonitorEvery", minimum: 1) {
    case .success(let found):
      stopMonitorEvery = found
    case .failure(let error):
      return .failure(error)
    }
    return .success((sampleCount, stopMonitorEvery))
  }

  /// Reads one optional boolean key. Only a real boolean counts:
  /// integers are refused the way booleans are refused for integers.
  static func checkedOptionalBool(
    _ dict: [String: Any],
    key: String
  ) -> Result<Bool?, ConfigDecodeError> {
    guard let rawValue = dict[key] else { return .success(nil) }
    guard
      let number = rawValue as? NSNumber,
      String(cString: number.objCType) == "c"
    else {
      return .failure(.invalidValue(key: key))
    }
    return .success(number.boolValue)
  }

  /// Reads one optional display-mode key. Anything but a `DisplayMode`
  /// word invalidates the whole file, like any other bad value.
  static func checkedOptionalMode(
    _ dict: [String: Any],
    key: String
  ) -> Result<DisplayMode?, ConfigDecodeError> {
    guard let rawValue = dict[key] else { return .success(nil) }
    guard let text = rawValue as? String, let mode = DisplayMode(rawValue: text) else {
      return .failure(.invalidValue(key: key))
    }
    return .success(mode)
  }

  /// Reads the optional appearance-mode key. Anything but an
  /// `AppearanceMode` word invalidates the whole file, like any other
  /// bad value.
  static func checkedOptionalAppearance(
    _ dict: [String: Any],
    key: String
  ) -> Result<AppearanceMode?, ConfigDecodeError> {
    guard let rawValue = dict[key] else { return .success(nil) }
    guard let text = rawValue as? String, let mode = AppearanceMode(rawValue: text) else {
      return .failure(.invalidValue(key: key))
    }
    return .success(mode)
  }

  /// Reads the optional romaji-scope key. Anything but a
  /// `RomajiScope` word invalidates the whole file, like any other
  /// bad value.
  static func checkedOptionalRomajiScope(
    _ dict: [String: Any],
    key: String
  ) -> Result<RomajiScope?, ConfigDecodeError> {
    guard let rawValue = dict[key] else { return .success(nil) }
    guard let text = rawValue as? String, let scope = RomajiScope(rawValue: text) else {
      return .failure(.invalidValue(key: key))
    }
    return .success(scope)
  }

  /// Reads the three search-quality keys together, so the assembly stays
  /// small. The length bound is 0 to 5: the lower bound rides on the
  /// shared reader, the upper bound refuses the whole file, like any
  /// other bad value.
  static func checkedSearchSettings(
    _ dict: [String: Any],
    into config: inout ValidConfiguration
  ) -> Result<Void, ConfigDecodeError> {
    switch checkedOptionalInt(dict, key: "shortcutMemoryLength", minimum: 0) {
    case .success(let found):
      guard found.map({ $0 <= 5 }) ?? true else {
        return .failure(.invalidValue(key: "shortcutMemoryLength"))
      }
      config.shortcutMemoryLength = found

    case .failure(let error):
      return .failure(error)
    }
    switch checkedOptionalBool(dict, key: "fuzzyMatchEnabled") {
    case .success(let found):
      config.fuzzyMatchEnabled = found
    case .failure(let error):
      return .failure(error)
    }
    switch checkedOptionalResultOrder(dict, key: "resultOrder") {
    case .success(let found):
      config.resultOrder = found
    case .failure(let error):
      return .failure(error)
    }
    return .success(())
  }

  /// Reads the optional ordering word. Only the two known words count:
  /// anything else invalidates the whole file, like any other bad value.
  static func checkedOptionalResultOrder(
    _ dict: [String: Any],
    key: String
  ) -> Result<String?, ConfigDecodeError> {
    guard let rawValue = dict[key] else { return .success(nil) }
    guard
      let text = rawValue as? String,
      text == "mru" || text == "score"
    else {
      return .failure(.invalidValue(key: key))
    }
    return .success(text)
  }

  /// Reads one optional channel key. Only the two known words count:
  /// anything else invalidates the whole file, like any other bad value.
  static func checkedOptionalChannel(
    _ dict: [String: Any],
    key: String
  ) -> Result<String?, ConfigDecodeError> {
    guard let rawValue = dict[key] else { return .success(nil) }
    guard
      let text = rawValue as? String,
      text == "stable" || text == "beta"
    else {
      return .failure(.invalidValue(key: key))
    }
    return .success(text)
  }

  /// Reads the optional exclusion list. The value must be an array;
  /// anything else invalidates the whole file. Elements that are not
  /// objects, or lack string app and titlePattern pairs, or carry
  /// extra keys, are skipped one by one while valid elements are kept.
  /// Value problems stay raw here: compiling reports what it skips, so
  /// decoding never decides what counts as unreadable.
  static func checkedOptionalExclusions(
    _ dict: [String: Any],
    key: String
  ) -> Result<[ExclusionEntry]?, ConfigDecodeError> {
    guard let rawValue = dict[key] else { return .success(nil) }
    guard let items = rawValue as? [Any] else {
      return .failure(.invalidValue(key: key))
    }
    var entries = [ExclusionEntry]()
    for item in items {
      guard
        let element = item as? [String: Any],
        Set(element.keys) == Set(["app", "titlePattern"]),
        let app = element["app"] as? String,
        let titlePattern = element["titlePattern"] as? String
      else {
        continue
      }
      entries.append(ExclusionEntry(app: app, titlePattern: titlePattern))
    }
    return .success(entries)
  }

  /// A JSON integer and nothing else.
  ///
  /// Booleans are refused by their Objective-C type: an `is Bool` check
  /// wrongly matches integer 1, so only the `c` type is turned away.
  static func jsonInt(_ value: Any) -> Int? {
    if let number = value as? NSNumber, String(cString: number.objCType) == "c" {
      return nil
    }
    return value as? Int
  }

  /// A JSON number and nothing else.
  ///
  /// Booleans are refused the way `jsonInt` refuses them. Integers
  /// count as their double value, so a spelled `1` reads as `1.0`.
  static func jsonDouble(_ value: Any) -> Double? {
    if let number = value as? NSNumber, String(cString: number.objCType) == "c" {
      return nil
    }
    return (value as? NSNumber)?.doubleValue
  }

  /// Reads the optional text-scale key leniently: absent means the
  /// standard size, a non-standard step wins, the standard step reads
  /// as absent so an explicit 1.0 stays omitted on save, and anything
  /// else falls back to standard with a note instead of failing the file.
  static func checkedOptionalTextScale(
    _ dict: [String: Any]
  ) -> (value: Double?, issue: String?) {
    guard let rawValue = dict["textScale"] else { return (nil, nil) }
    guard let factor = jsonDouble(rawValue), let level = TextScaleLevel(factor: factor) else {
      return (nil, "textScale is not a valid value; using 1.0")
    }
    if level == .standard {
      return (nil, nil)
    }
    return (factor, nil)
  }

  /// Reads the keybindings section leniently: malformed entries and
  /// unknown actions are dropped one by one with issues, never failing
  /// the file. Only a section that is not an object at all is a bad
  /// value, like any other misshapen key.
  static func checkedOptionalKeyBindings(
    _ dict: [String: Any]
  ) -> Result<([KeyBindingAction: [RawKeyBinding]], [KeyBindingIssue]), ConfigDecodeError> {
    guard let rawValue = dict["keybindings"] else { return .success(([:], [])) }
    guard let section = rawValue as? [String: Any] else {
      return .failure(.invalidValue(key: "keybindings"))
    }
    var out = [KeyBindingAction: [RawKeyBinding]]()
    var issues = [KeyBindingIssue]()
    for name in section.keys.sorted() {
      guard let action = KeyBindingAction(rawValue: name) else {
        issues.append(KeyBindingIssue(
          action: nil,
          reason: .invalid,
          detail: "unknown action \(name)"
        ))
        continue
      }
      guard let raws = section[name] as? [Any] else {
        issues.append(KeyBindingIssue(
          action: action,
          reason: .invalid,
          detail: "\(name) is not a list"
        ))
        continue
      }
      var entries = [RawKeyBinding]()
      for raw in raws {
        guard
          let entry = raw as? [String: Any],
          Set(entry.keys) == Set(["keyCode", "modifiers"]),
          let keyCode = jsonInt(entry["keyCode"] as Any),
          let modifiers = entry["modifiers"] as? [String]
        else {
          issues.append(KeyBindingIssue(
            action: action,
            reason: .invalid,
            detail: "\(name) holds a malformed entry"
          ))
          continue
        }
        entries.append(RawKeyBinding(keyCode: keyCode, modifiers: modifiers))
      }
      out[action] = entries
    }
    return .success((out, issues))
  }

  /// Folds the switcher sections over an otherwise valid file.
  ///
  /// The main section wins over the top-level keys item by item, while
  /// the parallel section builds follow-or-own choices instead. Shared
  /// keys in either section are ignored with a note; anything the file
  /// holds nowhere fails the whole file like any other unknown key, and
  /// a section that is not an object fails it like any other bad value.
  /// Absent sections change nothing: the file reads as it long has.
  static func withSwitcherSections(
    _ dict: [String: Any],
    decoded: DecodedConfiguration
  ) -> Result<DecodedConfiguration, ConfigDecodeError> {
    guard let raw = dict["switchers"] else { return .success(decoded) }
    guard let sections = raw as? [String: Any] else {
      return .failure(.invalidValue(key: "switchers"))
    }
    for key in sections.keys.sorted() where key != "main" && key != "parallel" {
      return .failure(.invalidValue(key: "switchers.\(key)"))
    }
    var decoded = decoded
    decoded.config.hasSwitchersSection = true
    if let mainRaw = sections["main"] {
      guard let main = mainRaw as? [String: Any] else {
        return .failure(.invalidValue(key: "switchers.main"))
      }
      for key in main.keys.sorted() where !switcherSectionKeys.contains(key) {
        return .failure(.invalidValue(key: "switchers.main.\(key)"))
      }
      applyMainSection(main, top: dict, config: &decoded.config, notes: &decoded.switcherNotes)
    }
    if let parallelRaw = sections["parallel"] {
      guard let parallel = parallelRaw as? [String: Any] else {
        return .failure(.invalidValue(key: "switchers.parallel"))
      }
      for key in parallel.keys.sorted()
        where key != "enabled" && !switcherSectionKeys.contains(key)
      {
        return .failure(.invalidValue(key: "switchers.parallel.\(key)"))
      }
      applyParallelSection(parallel, config: &decoded.config, notes: &decoded.switcherNotes)
    }
    return .success(decoded)
  }

  /// Folds one main section over the top-level values, noting what gave
  /// way. An unreadable item keeps the top-level value; a shared key is
  /// ignored in favour of the top level.
  static func applyMainSection(
    _ section: [String: Any],
    top: [String: Any],
    config: inout ValidConfiguration,
    notes: inout [String]
  ) {
    for key in section.keys.sorted() {
      guard switcherPanelKeys.contains(key) else {
        if deprecatedKeys.contains(key) {
          notes.append("switchers.main.\(key) is no longer used and was ignored")
        } else {
          notes.append(
            "switchers.main.\(key) is shared by both switchers; write it at the top level"
          )
        }
        continue
      }
      applyMainPanelKey(key: key, section: section, top: top, config: &config, notes: &notes)
    }
  }

  /// Builds the parallel choices beside the main values. An unreadable
  /// item follows the main switcher; a shared key is ignored in favour
  /// of the top level.
  static func applyParallelSection(
    _ section: [String: Any],
    config: inout ValidConfiguration,
    notes: inout [String]
  ) {
    var overrides = ParallelOverrides.defaults
    for key in section.keys.sorted() {
      if key == "enabled" {
        switch checkedOptionalBool(section, key: key) {
        case .success(let found):
          overrides.isEnabled = found ?? true
        case .failure:
          notes.append("switchers.parallel.enabled is not a valid value; staying on")
        }
        continue
      }
      guard switcherPanelKeys.contains(key) else {
        if deprecatedKeys.contains(key) {
          notes.append("switchers.parallel.\(key) is no longer used and was ignored")
        } else {
          notes.append(
            "switchers.parallel.\(key) is shared by both switchers; write it at the top level"
          )
        }
        continue
      }
      applyParallelPanelKey(key: key, section: section, overrides: &overrides, notes: &notes)
    }
    config.parallelOverrides = overrides
  }

  static func resolvedKeyBindings(
    _ dict: [String: Any],
    data: Data,
    config: ValidConfiguration,
    assumed: Bool
  ) -> Result<DecodedConfiguration, ConfigDecodeError> {
    switch checkedOptionalKeyBindings(dict) {
    case .success((let section, let decodeIssues)):
      var config = config
      let text = String(data: data, encoding: .utf8) ?? ""
      let order = KeyBindingResolver.declarationOrder(in: text)
      let (table, resolveIssues) = KeyBindingResolver.resolve(section, order: order)
      config.keyBindings = table
      config.keyBindingSection = section.isEmpty ? nil : section
      let (textScale, textScaleIssue) = checkedOptionalTextScale(dict)
      config.textScale = textScale
      let (panelWidth, panelWidthIssue) = checkedOptionalPanelWidth(dict)
      config.panelWidth = panelWidth
      let (showDelayMs, showDelayIssue) = checkedOptionalShowDelayMs(dict)
      config.showDelayMs = showDelayMs
      return .success(DecodedConfiguration(
        config: config,
        assumedVersion: assumed,
        keyBindingIssues: decodeIssues + resolveIssues,
        textScaleIssue: textScaleIssue,
        panelWidthIssue: panelWidthIssue,
        showDelayIssue: showDelayIssue,
        deprecatedKeys: deprecatedKeys.filter { dict[$0] != nil }
      ))

    case .failure(let error):
      return .failure(error)
    }
  }

  // MARK: Private

  /// Whether the spelled value asks to follow the main switcher.
  private static func isInherit(_ raw: Any?) -> Bool {
    raw as? String == "inherit"
  }

  /// What an unreadable main item falls back to.
  private static func mainFallbackWord(key: String, top: [String: Any]) -> String {
    top[key] != nil ? "the top-level key" : "the default"
  }

  /// One main-section display-mode key over the top-level value.
  private static func applyMainMode(
    key: String,
    section: [String: Any],
    top: [String: Any],
    config: inout ValidConfiguration,
    path: WritableKeyPath<ValidConfiguration, DisplayMode?>,
    notes: inout [String]
  ) {
    if isInherit(section[key]) {
      notes.append(
        "switchers.main.\(key) spells \"inherit\", which only the parallel section takes; "
          + "using \(mainFallbackWord(key: key, top: top))"
      )
      return
    }
    switch checkedOptionalMode(section, key: key) {
    case .success(let found):
      guard let mode = found else { return }
      config[keyPath: path] = mode
      if top[key] != nil {
        notes.append("top-level \(key) is unused; switchers.main.\(key) wins")
      }

    case .failure:
      notes.append(
        "switchers.main.\(key) is not a valid value; using \(mainFallbackWord(key: key, top: top))"
      )
    }
  }

  /// One main-section word key over the top-level value.
  private static func applyMainWord<Word: RawRepresentable<String>>(
    key: String,
    section: [String: Any],
    top: [String: Any],
    config: inout ValidConfiguration,
    path: WritableKeyPath<ValidConfiguration, Word?>,
    notes: inout [String]
  ) {
    if isInherit(section[key]) {
      notes.append(
        "switchers.main.\(key) spells \"inherit\", which only the parallel section takes; "
          + "using \(mainFallbackWord(key: key, top: top))"
      )
      return
    }
    switch checkedOptionalWord(section, key: key, as: Word.self) {
    case .success(let found):
      guard let word = found else { return }
      config[keyPath: path] = word
      if top[key] != nil {
        notes.append("top-level \(key) is unused; switchers.main.\(key) wins")
      }

    case .failure:
      notes.append(
        "switchers.main.\(key) is not a valid value; using \(mainFallbackWord(key: key, top: top))"
      )
    }
  }

  /// One main-section on-off key over the top-level value.
  private static func applyMainSwitch(
    key: String,
    section: [String: Any],
    top: [String: Any],
    config: inout ValidConfiguration,
    path: WritableKeyPath<ValidConfiguration, Bool?>,
    notes: inout [String]
  ) {
    if isInherit(section[key]) {
      notes.append(
        "switchers.main.\(key) spells \"inherit\", which only the parallel section takes; "
          + "using \(mainFallbackWord(key: key, top: top))"
      )
      return
    }
    switch checkedOptionalBool(section, key: key) {
    case .success(let found):
      guard let enabled = found else { return }
      config[keyPath: path] = enabled
      if top[key] != nil {
        notes.append("top-level \(key) is unused; switchers.main.\(key) wins")
      }

    case .failure:
      notes.append(
        "switchers.main.\(key) is not a valid value; using \(mainFallbackWord(key: key, top: top))"
      )
    }
  }

  /// One main-section panel key over the top-level value, by kind.
  private static func applyMainPanelKey(
    key: String,
    section: [String: Any],
    top: [String: Any],
    config: inout ValidConfiguration,
    notes: inout [String]
  ) {
    switch key {
    case "otherSpaceMode":
      applyMainMode(key: key, section: section, top: top, config: &config, path: \.otherSpaceMode, notes: &notes)
    case "hiddenAppMode":
      applyMainMode(key: key, section: section, top: top, config: &config, path: \.hiddenAppMode, notes: &notes)
    case "minimizedMode":
      applyMainMode(key: key, section: section, top: top, config: &config, path: \.minimizedMode, notes: &notes)
    case "fullscreenMode":
      applyMainMode(key: key, section: section, top: top, config: &config, path: \.fullscreenMode, notes: &notes)
    case "windowlessAppMode":
      applyMainMode(key: key, section: section, top: top, config: &config, path: \.windowlessAppMode, notes: &notes)
    case "windowScope":
      applyMainWord(key: key, section: section, top: top, config: &config, path: \.windowScope, notes: &notes)
    case "numberScope":
      applyMainWord(key: key, section: section, top: top, config: &config, path: \.numberScope, notes: &notes)
    case "hintsMode":
      applyMainWord(key: key, section: section, top: top, config: &config, path: \.hintsMode, notes: &notes)
    case "grouping":
      applyMainWord(key: key, section: section, top: top, config: &config, path: \.grouping, notes: &notes)
    case "displayTarget":
      applyMainWord(key: key, section: section, top: top, config: &config, path: \.displayTarget, notes: &notes)
    case "groupHeadingStyle":
      applyMainWord(key: key, section: section, top: top, config: &config, path: \.groupHeadingStyle, notes: &notes)
    case "otherSpacePlacement",
         "hiddenAppPlacement",
         "minimizedPlacement",
         "fullscreenPlacement",
         "windowlessAppPlacement":
      applyMainPlacement(key: key, section: section, top: top, config: &config, notes: &notes)
    case "resultOrder":
      applyMainResultOrder(section: section, top: top, config: &config, notes: &notes)
    case "groupCount":
      applyMainGroupCount(section: section, top: top, config: &config, notes: &notes)
    case "fuzzyMatchEnabled":
      applyMainSwitch(key: key, section: section, top: top, config: &config, path: \.fuzzyMatchEnabled, notes: &notes)
    case "hoverSelect":
      applyMainSwitch(key: key, section: section, top: top, config: &config, path: \.hoverSelect, notes: &notes)
    case "scrollSelect":
      applyMainSwitch(key: key, section: section, top: top, config: &config, path: \.scrollSelect, notes: &notes)
    case "numberJump":
      applyMainSwitch(key: key, section: section, top: top, config: &config, path: \.numberJump, notes: &notes)
    case "numberReorder":
      applyMainSwitch(key: key, section: section, top: top, config: &config, path: \.numberReorder, notes: &notes)
    case "textScale":
      applyMainTextScale(section: section, top: top, config: &config, notes: &notes)
    case "panelWidth":
      applyMainPanelWidth(section: section, top: top, config: &config, notes: &notes)
    case "showDelayMs":
      applyMainShowDelay(section: section, top: top, config: &config, notes: &notes)
    default:
      break
    }
  }

  /// One main-section parked-section key over the top-level value.
  private static func applyMainPlacement(
    key: String,
    section: [String: Any],
    top: [String: Any],
    config: inout ValidConfiguration,
    notes: inout [String]
  ) {
    guard let subgroup = placementKeys.first(where: { $0.0 == key })?.1 else { return }
    if isInherit(section[key]) {
      notes.append(
        "switchers.main.\(key) spells \"inherit\", which only the parallel section takes; "
          + "using \(mainFallbackWord(key: key, top: top))"
      )
      return
    }
    switch checkedOptionalWord(section, key: key, as: SubgroupPlacement.self) {
    case .success(let found):
      guard let placement = found else { return }
      config.subgroupPlacements[subgroup] = placement
      if top[key] != nil {
        notes.append("top-level \(key) is unused; switchers.main.\(key) wins")
      }

    case .failure:
      notes.append(
        "switchers.main.\(key) is not a valid value; using \(mainFallbackWord(key: key, top: top))"
      )
    }
  }

  /// The main-section ordering word over the top-level value.
  private static func applyMainResultOrder(
    section: [String: Any],
    top: [String: Any],
    config: inout ValidConfiguration,
    notes: inout [String]
  ) {
    let key = "resultOrder"
    if isInherit(section[key]) {
      notes.append(
        "switchers.main.\(key) spells \"inherit\", which only the parallel section takes; "
          + "using \(mainFallbackWord(key: key, top: top))"
      )
      return
    }
    switch checkedOptionalResultOrder(section, key: key) {
    case .success(let found):
      guard let order = found else { return }
      config.resultOrder = order
      if top[key] != nil {
        notes.append("top-level \(key) is unused; switchers.main.\(key) wins")
      }

    case .failure:
      notes.append(
        "switchers.main.\(key) is not a valid value; using \(mainFallbackWord(key: key, top: top))"
      )
    }
  }

  /// The main-section group count over the top-level value.
  private static func applyMainGroupCount(
    section: [String: Any],
    top: [String: Any],
    config: inout ValidConfiguration,
    notes: inout [String]
  ) {
    let key = "groupCount"
    if isInherit(section[key]) {
      notes.append(
        "switchers.main.\(key) spells \"inherit\", which only the parallel section takes; "
          + "using \(mainFallbackWord(key: key, top: top))"
      )
      return
    }
    switch checkedOptionalInt(section, key: key, minimum: 1) {
    case .success(let found):
      guard let count = found, count <= maximumGroupCount else {
        if found != nil {
          notes.append(
            "switchers.main.\(key) is not a valid value; using \(mainFallbackWord(key: key, top: top))"
          )
        }
        return
      }
      config.groupCount = count
      if top[key] != nil {
        notes.append("top-level \(key) is unused; switchers.main.\(key) wins")
      }

    case .failure:
      notes.append(
        "switchers.main.\(key) is not a valid value; using \(mainFallbackWord(key: key, top: top))"
      )
    }
  }

  /// The main-section text scale over the top-level value.
  private static func applyMainTextScale(
    section: [String: Any],
    top: [String: Any],
    config: inout ValidConfiguration,
    notes: inout [String]
  ) {
    let key = "textScale"
    if isInherit(section[key]) {
      notes.append(
        "switchers.main.\(key) spells \"inherit\", which only the parallel section takes; "
          + "using \(mainFallbackWord(key: key, top: top))"
      )
      return
    }
    let (value, issue) = checkedOptionalTextScale(section)
    if issue != nil {
      notes.append(
        "switchers.main.\(key) is not a valid value; using \(mainFallbackWord(key: key, top: top))"
      )
      return
    }
    guard let factor = value else { return }
    config.textScale = factor
    if top[key] != nil {
      notes.append("top-level \(key) is unused; switchers.main.\(key) wins")
    }
  }

  /// The main-section panel width over the top-level value.
  private static func applyMainPanelWidth(
    section: [String: Any],
    top: [String: Any],
    config: inout ValidConfiguration,
    notes: inout [String]
  ) {
    let key = "panelWidth"
    if isInherit(section[key]) {
      notes.append(
        "switchers.main.\(key) spells \"inherit\", which only the parallel section takes; "
          + "using \(mainFallbackWord(key: key, top: top))"
      )
      return
    }
    let (value, issue) = checkedOptionalPanelWidth(section)
    if issue != nil {
      notes.append(
        "switchers.main.\(key) is not a valid value; using \(mainFallbackWord(key: key, top: top))"
      )
      return
    }
    guard let factor = value else { return }
    config.panelWidth = factor
    if top[key] != nil {
      notes.append("top-level \(key) is unused; switchers.main.\(key) wins")
    }
  }

  /// The main-section show delay over the top-level value.
  private static func applyMainShowDelay(
    section: [String: Any],
    top: [String: Any],
    config: inout ValidConfiguration,
    notes: inout [String]
  ) {
    let key = "showDelayMs"
    if isInherit(section[key]) {
      notes.append(
        "switchers.main.\(key) spells \"inherit\", which only the parallel section takes; "
          + "using \(mainFallbackWord(key: key, top: top))"
      )
      return
    }
    let (value, issue) = checkedOptionalShowDelayMs(section)
    if issue != nil {
      notes.append(
        "switchers.main.\(key) is not a valid value; using \(mainFallbackWord(key: key, top: top))"
      )
      return
    }
    guard let milliseconds = value else { return }
    config.showDelayMs = milliseconds
    if top[key] != nil {
      notes.append("top-level \(key) is unused; switchers.main.\(key) wins")
    }
  }

  /// One parallel-section display-mode choice.
  private static func readParallelMode(
    key: String,
    section: [String: Any],
    notes: inout [String]
  ) -> FollowOrOwn<DisplayMode> {
    if isInherit(section[key]) {
      return .follow
    }
    switch checkedOptionalMode(section, key: key) {
    case .success(let found):
      guard let mode = found else { return .follow }
      return .own(mode)

    case .failure:
      notes.append("switchers.parallel.\(key) is not a valid value; following the main switcher")
      return .follow
    }
  }

  /// One parallel-section word choice.
  private static func readParallelWord<Word: RawRepresentable<String>>(
    key: String,
    section: [String: Any],
    notes: inout [String]
  ) -> FollowOrOwn<Word> {
    if isInherit(section[key]) {
      return .follow
    }
    switch checkedOptionalWord(section, key: key, as: Word.self) {
    case .success(let found):
      guard let word = found else { return .follow }
      return .own(word)

    case .failure:
      notes.append("switchers.parallel.\(key) is not a valid value; following the main switcher")
      return .follow
    }
  }

  /// One parallel-section on-off choice.
  private static func readParallelSwitch(
    key: String,
    section: [String: Any],
    notes: inout [String]
  ) -> FollowOrOwn<Bool> {
    if isInherit(section[key]) {
      return .follow
    }
    switch checkedOptionalBool(section, key: key) {
    case .success(let found):
      guard let enabled = found else { return .follow }
      return .own(enabled)

    case .failure:
      notes.append("switchers.parallel.\(key) is not a valid value; following the main switcher")
      return .follow
    }
  }

  /// One parallel-section panel choice, by kind.
  private static func applyParallelPanelKey(
    key: String,
    section: [String: Any],
    overrides: inout ParallelOverrides,
    notes: inout [String]
  ) {
    switch key {
    case "windowScope":
      if isInherit(section[key]) {
        overrides.windowScope = .follow
        return
      }
      switch checkedOptionalWord(section, key: key, as: WindowScope.self) {
      case .success(let found):
        guard let scope = found else { return }
        overrides.windowScope = .own(scope)

      case .failure:
        notes.append(
          "switchers.parallel.\(key) is not a valid value; showing the front application alone"
        )
        overrides.windowScope = .own(.frontApp)
      }

    case "otherSpaceMode":
      overrides.otherSpaceMode = readParallelMode(key: key, section: section, notes: &notes)

    case "hiddenAppMode":
      overrides.hiddenAppMode = readParallelMode(key: key, section: section, notes: &notes)

    case "minimizedMode":
      overrides.minimizedMode = readParallelMode(key: key, section: section, notes: &notes)

    case "fullscreenMode":
      overrides.fullscreenMode = readParallelMode(key: key, section: section, notes: &notes)

    case "windowlessAppMode":
      overrides.windowlessAppMode = readParallelMode(key: key, section: section, notes: &notes)

    case "numberScope":
      overrides.numberScope = readParallelWord(key: key, section: section, notes: &notes)

    case "hintsMode":
      overrides.hintsMode = readParallelWord(key: key, section: section, notes: &notes)

    case "grouping":
      overrides.groupingMode = readParallelWord(key: key, section: section, notes: &notes)

    case "displayTarget":
      overrides.displayTarget = readParallelWord(key: key, section: section, notes: &notes)

    case "groupHeadingStyle":
      overrides.groupHeadingStyle = readParallelWord(key: key, section: section, notes: &notes)

    case "otherSpacePlacement",
         "hiddenAppPlacement",
         "minimizedPlacement",
         "fullscreenPlacement",
         "windowlessAppPlacement":
      applyParallelPlacement(key: key, section: section, overrides: &overrides, notes: &notes)

    case "resultOrder":
      if isInherit(section[key]) {
        overrides.resultOrder = .follow
        return
      }
      switch checkedOptionalResultOrder(section, key: key) {
      case .success(let found):
        guard let order = found else { return }
        overrides.resultOrder = .own(SearchOrdering(rawValue: order) ?? .mru)

      case .failure:
        notes.append("switchers.parallel.\(key) is not a valid value; following the main switcher")
        overrides.resultOrder = .follow
      }

    case "groupCount":
      applyParallelGroupCount(section: section, overrides: &overrides, notes: &notes)

    case "fuzzyMatchEnabled":
      overrides.fuzzyMatchEnabled = readParallelSwitch(key: key, section: section, notes: &notes)

    case "hoverSelect":
      overrides.hoverSelect = readParallelSwitch(key: key, section: section, notes: &notes)

    case "scrollSelect":
      overrides.scrollSelect = readParallelSwitch(key: key, section: section, notes: &notes)

    case "numberJump":
      overrides.numberJump = readParallelSwitch(key: key, section: section, notes: &notes)

    case "numberReorder":
      overrides.numberReorder = readParallelSwitch(key: key, section: section, notes: &notes)

    case "textScale":
      applyParallelTextScale(section: section, overrides: &overrides, notes: &notes)

    case "panelWidth":
      applyParallelPanelWidth(section: section, overrides: &overrides, notes: &notes)

    case "showDelayMs":
      applyParallelShowDelay(section: section, overrides: &overrides, notes: &notes)

    default:
      break
    }
  }

  /// One parallel-section parked-section choice.
  private static func applyParallelPlacement(
    key: String,
    section: [String: Any],
    overrides: inout ParallelOverrides,
    notes: inout [String]
  ) {
    let choice: FollowOrOwn<SubgroupPlacement> = readParallelWord(key: key, section: section, notes: &notes)
    switch key {
    case "otherSpacePlacement": overrides.otherSpacePlacement = choice
    case "hiddenAppPlacement": overrides.hiddenAppPlacement = choice
    case "minimizedPlacement": overrides.minimizedPlacement = choice
    case "fullscreenPlacement": overrides.fullscreenPlacement = choice
    default: overrides.windowlessAppPlacement = choice
    }
  }

  /// The parallel-section group count choice.
  private static func applyParallelGroupCount(
    section: [String: Any],
    overrides: inout ParallelOverrides,
    notes: inout [String]
  ) {
    let key = "groupCount"
    if isInherit(section[key]) {
      overrides.groupCount = .follow
      return
    }
    switch checkedOptionalInt(section, key: key, minimum: 1) {
    case .success(let found):
      guard let count = found, count <= maximumGroupCount else {
        if found != nil {
          notes.append("switchers.parallel.\(key) is not a valid value; following the main switcher")
          overrides.groupCount = .follow
        }
        return
      }
      overrides.groupCount = .own(count)

    case .failure:
      notes.append("switchers.parallel.\(key) is not a valid value; following the main switcher")
      overrides.groupCount = .follow
    }
  }

  /// The parallel-section text-scale choice.
  private static func applyParallelTextScale(
    section: [String: Any],
    overrides: inout ParallelOverrides,
    notes: inout [String]
  ) {
    let key = "textScale"
    if isInherit(section[key]) {
      overrides.textScale = .follow
      return
    }
    let (value, issue) = checkedOptionalTextScale(section)
    if issue != nil {
      notes.append("switchers.parallel.\(key) is not a valid value; following the main switcher")
      overrides.textScale = .follow
      return
    }
    guard let factor = value else {
      if section[key] != nil {
        overrides.textScale = .own(.standard)
      }
      return
    }
    overrides.textScale = .own(TextScaleLevel(factor: factor) ?? .standard)
  }

  /// The parallel-section panel-width choice.
  private static func applyParallelPanelWidth(
    section: [String: Any],
    overrides: inout ParallelOverrides,
    notes: inout [String]
  ) {
    let key = "panelWidth"
    if isInherit(section[key]) {
      overrides.panelWidth = .follow
      return
    }
    let (value, issue) = checkedOptionalPanelWidth(section)
    if issue != nil {
      notes.append("switchers.parallel.\(key) is not a valid value; following the main switcher")
      overrides.panelWidth = .follow
      return
    }
    guard let factor = value else {
      if section[key] != nil {
        overrides.panelWidth = .own(.standard)
      }
      return
    }
    overrides.panelWidth = .own(PanelWidth(factor: factor) ?? .standard)
  }

  /// The parallel-section show-delay choice.
  private static func applyParallelShowDelay(
    section: [String: Any],
    overrides: inout ParallelOverrides,
    notes: inout [String]
  ) {
    let key = "showDelayMs"
    if isInherit(section[key]) {
      overrides.showDelayMs = .follow
      return
    }
    let (value, issue) = checkedOptionalShowDelayMs(section)
    if issue != nil {
      notes.append("switchers.parallel.\(key) is not a valid value; following the main switcher")
      overrides.showDelayMs = .follow
      return
    }
    guard let milliseconds = value else {
      if section[key] != nil {
        overrides.showDelayMs = .own(nil)
      }
      return
    }
    overrides.showDelayMs = .own(milliseconds)
  }

}
