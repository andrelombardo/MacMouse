import AppKit
import ApplicationServices
import Carbon.HIToolbox
#if SWIFT_PACKAGE
import MacMouseCore
#endif

/// Maps printable shortcut keys using the active keyboard layout, including Italian.
enum KeyboardLayout {
    static func keyCode(for character: String) -> UInt16? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return nil }
        let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue()
        let layout = unsafeBitCast(CFDataGetBytePtr(data), to: UnsafePointer<UCKeyboardLayout>.self)
        for key: UInt16 in 0..<128 {
            var state: UInt32 = 0
            var length = 0
            var chars = [UniChar](repeating: 0, count: 8)
            let result = UCKeyTranslate(layout, key, UInt16(kUCKeyActionDisplay), 0,
                                        UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit),
                                        &state, chars.count, &length, &chars)
            if result == noErr, String(utf16CodeUnits: chars, count: length).lowercased() == character.lowercased() {
                return key
            }
        }
        return nil
    }
}

@MainActor
final class ActionExecutor {
    var onError: ((String) -> Void)?
    private let navigationQueue = DispatchQueue(label: "MacMouse.Navigation", qos: .userInteractive)
    private let cancellation = NavigationCancellation()

    func cancelPending() { cancellation.cancel() }

    func execute(_ action: ButtonAction) {
        guard AXIsProcessTrusted(), CGPreflightPostEventAccess() else {
            onError?("Accessibilità non disponibile. Verifica le autorizzazioni.")
            return
        }
        switch action.kind {
        case .back, .forward:
            guard let application = NSWorkspace.shared.frontmostApplication else { return }
            let pid = application.processIdentifier
            let backward = action.kind == .back
            let character = backward ? "[" : "]"
            // Do not send a navigation shortcut into unrelated apps where it may edit text.
            let knownNavigation = ["com.apple.Safari", "com.apple.finder"].contains(application.bundleIdentifier ?? "")
            let fallback = knownNavigation ? KeyboardLayout.keyCode(for: character) : nil
            let cancellation = cancellation
            let generation = cancellation.current
            navigationQueue.async { [weak self] in
                guard cancellation.isCurrent(generation) else { return }
                if !NavigationMenu.press(pid: pid, backward: backward, isCurrent: { cancellation.isCurrent(generation) }) {
                    // Do not send a delayed fallback into a newly activated application.
                    Task { @MainActor [weak self] in
                        guard cancellation.isCurrent(generation),
                              NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else { return }
                        if let fallback { Self.post(.init(keyCode: fallback, modifiers: 0x100000, keyLabel: character)) }
                        else { self?.onError?("Navigazione non disponibile in questa app o con questo layout. Usa una scorciatoia personalizzata.") }
                    }
                }
            }
        case .openApplication:
            guard let path = action.applicationPath, FileManager.default.fileExists(atPath: path) else {
                onError?("Applicazione non trovata. Selezionala nuovamente dal menu del pulsante.")
                return
            }
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: path), configuration: .init()) { [weak self] _, error in
                if error != nil { Task { @MainActor in self?.onError?("Impossibile aprire l’applicazione selezionata.") } }
            }
        case .original, .disabled, .middleClick: break
        default:
            if let shortcut = action.shortcut ?? defaultShortcut(for: action.kind) { Self.post(shortcut) }
            else { onError?("Registra la scorciatoia di sistema per questa azione.") }
        }
    }

    private func defaultShortcut(for kind: ActionKind) -> Shortcut? {
        switch kind {
        case .missionControl: .init(keyCode: 126, modifiers: 0x40000, keyLabel: "↑")
        case .desktopLeft: .init(keyCode: UInt16(kVK_LeftArrow), modifiers: 0x40000, keyLabel: "←")
        case .desktopRight: .init(keyCode: UInt16(kVK_RightArrow), modifiers: 0x40000, keyLabel: "→")
        case .appExpose: .init(keyCode: 125, modifiers: 0x40000, keyLabel: "↓")
        case .showDesktop: .init(keyCode: 103, modifiers: 0, keyLabel: "F11")
        case .switchApplication: .init(keyCode: 48, modifiers: 0x100000, keyLabel: "⇥")
        case .closeWindow: characterShortcut("w")
        case .hideApplication: characterShortcut("h")
        case .switchWindow: characterShortcut("`")
        default: nil
        }
    }
    private func characterShortcut(_ character: String) -> Shortcut? {
        KeyboardLayout.keyCode(for: character).map { .init(keyCode: $0, modifiers: 0x100000, keyLabel: character.uppercased()) }
    }

    static func post(_ shortcut: Shortcut) {
        // A complete chord per physical press. Modifiers are event flags, never held keys.
        for event in SyntheticEvents.keyboard(for: shortcut) { event.post(tap: .cgSessionEventTap) }
    }
}

private final class NavigationCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var generation: UInt64 = 0
    var current: UInt64 { lock.withLock { generation } }
    func cancel() { lock.withLock { generation &+= 1 } }
    func isCurrent(_ value: UInt64) -> Bool { lock.withLock { generation == value } }
}

private enum NavigationMenu {
    static func press(pid: pid_t, backward: Bool, isCurrent: @Sendable () -> Bool) -> Bool {
        let application = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(application, 0.05)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(application, kAXMenuBarAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return false }
        let menuBar = unsafeDowncast(value, to: AXUIElement.self)
        let titles = backward ? ["indietro", "back", "go back"] : ["avanti", "forward", "go forward"]
        let deadline = ProcessInfo.processInfo.systemUptime + 0.18
        var remaining = 100
        func visit(_ element: AXUIElement, depth: Int) -> Bool {
            guard isCurrent(), depth <= 4, remaining > 0, ProcessInfo.processInfo.systemUptime < deadline else { return false }
            remaining -= 1
            var title: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &title) == .success,
               let text = title as? String, titles.contains(text.lowercased()) {
                var enabled: CFTypeRef?
                AXUIElementCopyAttributeValue(element, kAXEnabledAttribute as CFString, &enabled)
                if (enabled as? Bool) == true, isCurrent(),
                   AXUIElementPerformAction(element, kAXPressAction as CFString) == .success { return true }
            }
            var children: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children) == .success,
               let items = children as? [AXUIElement] {
                for child in items where visit(child, depth: depth + 1) { return true }
            }
            return false
        }
        // Prioritize navigation menus rather than exhausting the budget on File/Edit.
        var rootsValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(menuBar, kAXChildrenAttribute as CFString, &rootsValue) == .success,
              let roots = rootsValue as? [AXUIElement] else { return false }
        let preferred = ["cronologia", "history", "vai", "go", "naviga", "navigate", "vista", "view"]
        var ranked: [(rank: Int, index: Int, element: AXUIElement)] = []
        for (index, element) in roots.enumerated() {
            var title: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &title)
            let name = (title as? String ?? "").lowercased()
            let rank = preferred.firstIndex(of: name) ?? preferred.count
            ranked.append((rank, index, element))
        }
        ranked.sort { left, right in
            if left.rank != right.rank { return left.rank < right.rank }
            return left.index < right.index
        }
        for item in ranked {
            if visit(item.element, depth: 1) { return true }
        }
        return false
    }
}
