import AppKit
@preconcurrency import ApplicationServices
import ServiceManagement
#if SWIFT_PACKAGE
import MacMouseCore
#endif

@MainActor
final class PermissionService: ObservableObject {
    @Published private(set) var snapshot = PermissionSnapshot(accessibility: false, posting: false)
    var ready: Bool { snapshot.ready }
    var canFilterMouse: Bool { snapshot.canFilterMouse }
    var title: String {
        switch snapshot.state {
        case .accessibilityRequired: "Accessibilità da consentire"
        case .postingRequired: "Invio delle scorciatoie da consentire"
        case .ready: "Accessibilità consentita"
        }
    }
    func refresh() {
        let current = PermissionSnapshot(accessibility: AXIsProcessTrusted(), posting: CGPreflightPostEventAccess())
        if current != snapshot { snapshot = current }
    }
    func request() {
        if snapshot.state == .postingRequired {
            _ = CGRequestPostEventAccess()
            openSettings()
            refresh()
            return
        }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        openSettings()
    }
    func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}

@MainActor
final class LoginService: ObservableObject {
    @Published private(set) var enabled = false
    @Published private(set) var needsApproval = false
    @Published var error: String?
    func refresh() {
        let status = SMAppService.mainApp.status
        let currentEnabled = status == .enabled
        let currentApproval = status == .requiresApproval
        if enabled != currentEnabled { enabled = currentEnabled }
        if needsApproval != currentApproval { needsApproval = currentApproval }
    }
    func setEnabled(_ value: Bool) {
        do {
            if value { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            refresh()
            if needsApproval { SMAppService.openSystemSettingsLoginItems() }
        } catch {
            self.error = "Impossibile modificare l’avvio al login: \(error.localizedDescription)"
            refresh()
        }
    }
    func openSettings() { SMAppService.openSystemSettingsLoginItems() }
}
