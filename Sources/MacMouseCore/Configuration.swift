import Foundation

public struct Shortcut: Codable, Equatable, Sendable {
    public var keyCode: UInt16
    public var modifiers: UInt64
    public var keyLabel: String

    // Only Command, Shift, Option and Control are persisted.
    public static let modifierMask: UInt64 = 0x1E0000
    public init(keyCode: UInt16, modifiers: UInt64, keyLabel: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers & Self.modifierMask
        self.keyLabel = String(keyLabel.prefix(24))
    }
    public var isValid: Bool {
        keyCode <= 127 && ![54, 55, 56, 57, 58, 59, 60, 61, 62, 63].contains(keyCode)
            && modifiers & ~Self.modifierMask == 0 && !keyLabel.isEmpty && keyLabel.count <= 24
    }
    public var display: String {
        [(UInt64(0x40000), "⌃"), (0x80000, "⌥"), (0x20000, "⇧"), (0x100000, "⌘")]
            .filter { modifiers & $0.0 != 0 }.map(\.1).joined() + keyLabel
    }
}

public enum ActionKind: String, Codable, CaseIterable, Sendable {
    case back, forward, missionControl, desktopLeft, desktopRight, appExpose, showDesktop, switchApplication, launchpad
    case openApplication, closeWindow, hideApplication, switchWindow, shortcut, original, disabled, middleClick

    public var title: String {
        switch self {
        case .back: "Indietro"
        case .forward: "Avanti"
        case .missionControl: "Mission Control"
        case .desktopLeft: "Scrivania a sinistra"
        case .desktopRight: "Scrivania a destra"
        case .appExpose: "App Exposé"
        case .showDesktop: "Mostra scrivania"
        case .switchApplication: "Cambio applicazione"
        case .launchpad: "Launchpad / Applicazioni"
        case .openApplication: "Apri un’applicazione…"
        case .closeWindow: "Chiudi finestra"
        case .hideApplication: "Nascondi applicazione"
        case .switchWindow: "Cambio finestra"
        case .shortcut: "Scorciatoia personalizzata…"
        case .original: "Mantieni azione originale"
        case .disabled: "Disabilita pulsante"
        case .middleClick: "Clic centrale"
        }
    }
    public var supportsShortcutOverride: Bool {
        [.missionControl, .desktopLeft, .desktopRight, .appExpose, .showDesktop, .switchApplication, .launchpad,
         .closeWindow, .hideApplication, .switchWindow, .shortcut].contains(self)
    }
}

public struct ButtonAction: Codable, Equatable, Sendable {
    public var kind: ActionKind
    public var shortcut: Shortcut?
    public var applicationPath: String?
    public init(_ kind: ActionKind, shortcut: Shortcut? = nil, applicationPath: String? = nil) {
        self.kind = kind
        self.shortcut = shortcut
        self.applicationPath = applicationPath
    }
    public var isConfigured: Bool {
        switch kind {
        case .shortcut, .launchpad: shortcut?.isValid == true
        case .openApplication: applicationPath?.hasPrefix("/") == true && applicationPath?.hasSuffix(".app") == true
        default: true
        }
    }
}

public struct ButtonBinding: Codable, Equatable, Identifiable, Sendable {
    public var id: Int
    public var buttonNumber: Int?
    public var action: ButtonAction
    public init(id: Int, buttonNumber: Int? = nil, action: ButtonAction) {
        self.id = id
        self.buttonNumber = buttonNumber
        self.action = action
    }
}

public struct Configuration: Codable, Equatable, Sendable {
    public var schemaVersion = 1
    public var enabled = true
    public var reverseMouseScrolling = false
    public var showMenuBarIcon = true
    public var bindings: [ButtonBinding]
    public init() {
        bindings = [.init(id: 0, action: .init(.back)), .init(id: 1, action: .init(.forward))]
    }
    private enum CodingKeys: String, CodingKey {
        case schemaVersion, enabled, reverseMouseScrolling, showMenuBarIcon, bindings
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        enabled = try values.decode(Bool.self, forKey: .enabled)
        bindings = try values.decode([ButtonBinding].self, forKey: .bindings)
        // Preserve existing button assignments when upgrading from 0.1.x.
        reverseMouseScrolling = try values.decodeIfPresent(Bool.self, forKey: .reverseMouseScrolling) ?? false
        showMenuBarIcon = try values.decodeIfPresent(Bool.self, forKey: .showMenuBarIcon) ?? true
    }
    public var isValid: Bool {
        guard schemaVersion == 1, bindings.count == 2, bindings.map(\.id).sorted() == [0, 1] else { return false }
        let numbers = bindings.compactMap(\.buttonNumber)
        return numbers.allSatisfy { (2...31).contains($0) }
            && Set(numbers).count == numbers.count
            && bindings.allSatisfy { $0.action.shortcut == nil || $0.action.shortcut?.isValid == true }
    }
    public mutating func assign(button: Int, to id: Int) -> Bool {
        guard (2...31).contains(button), let index = bindings.firstIndex(where: { $0.id == id }),
              !bindings.contains(where: { $0.id != id && $0.buttonNumber == button }) else { return false }
        bindings[index].buttonNumber = button
        return true
    }
}

public final class PreferencesStore {
    private let defaults: UserDefaults
    private let key = "configuration.v1"
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    public func load() -> (configuration: Configuration, recovered: Bool) {
        guard let data = defaults.data(forKey: key) else { return (.init(), false) }
        guard let value = try? JSONDecoder().decode(Configuration.self, from: data), value.isValid else {
            return (.init(), true)
        }
        return (value, false)
    }
    @discardableResult public func save(_ value: Configuration) -> Bool {
        guard value.isValid, let data = try? JSONEncoder().encode(value) else { return false }
        defaults.set(data, forKey: key)
        return true
    }
}
