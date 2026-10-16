import Foundation
import Testing
@testable import MacMouseCore

@Test func defaultsNeverAssumeHardwareButtonCodes() {
    let config = Configuration()
    #expect(config.isValid)
    #expect(config.bindings.compactMap(\.buttonNumber).isEmpty)
    #expect(config.bindings.map(\.action.kind) == [.back, .forward])
}
@Test func assignmentRejectsDuplicatesAndPrimaryButtons() {
    var config = Configuration()
    let results = [config.assign(button: 0, to: 0), config.assign(button: 1, to: 0),
                   config.assign(button: 9, to: 0), config.assign(button: 9, to: 1),
                   config.assign(button: 32, to: 1), config.assign(button: 8, to: 99)]
    #expect(results == [false, false, true, false, false, false])
    #expect(config.isValid)
}
@Test func persistenceRoundTripsWithCustomShortcut() throws {
    let suite = "MacMouse.Tests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = PreferencesStore(defaults: defaults)
    var config = Configuration()
    _ = config.assign(button: 15, to: 0)
    config.bindings[0].action = .init(.shortcut, shortcut: .init(keyCode: 123, modifiers: 0x1E0000, keyLabel: "←"))
    config.enabled = false
    #expect(store.save(config))
    #expect(store.load().configuration == config)
    #expect(!store.load().recovered)
}
@Test func corruptAndFutureConfigurationsRecoverSafely() throws {
    let suite = "MacMouse.Tests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = PreferencesStore(defaults: defaults)
    defaults.set(Data("invalid".utf8), forKey: "configuration.v1")
    #expect(store.load().recovered)
    #expect(store.load().configuration == Configuration())
    var future = Configuration()
    future.schemaVersion = 20
    defaults.set(try JSONEncoder().encode(future), forKey: "configuration.v1")
    #expect(store.load().recovered)
    #expect(!store.save(future))
    var duplicated = Configuration()
    duplicated.bindings[0].buttonNumber = 5
    duplicated.bindings[1].buttonNumber = 5
    #expect(!store.save(duplicated))
}
@Test func shortcutModifiersAndFunctionKeysValidate() {
    let shortcut = Shortcut(keyCode: 122, modifiers: UInt64.max, keyLabel: "F1")
    #expect(shortcut.modifiers == Shortcut.modifierMask)
    #expect(shortcut.display == "⌃⌥⇧⌘F1")
    #expect(shortcut.isValid)
    #expect(!Shortcut(keyCode: 55, modifiers: 0, keyLabel: "⌘").isValid)
    #expect(!Shortcut(keyCode: 180, modifiers: 0, keyLabel: "?").isValid)
    #expect(!Shortcut(keyCode: 0, modifiers: 0, keyLabel: "").isValid)
}
