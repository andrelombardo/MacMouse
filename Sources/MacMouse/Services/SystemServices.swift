import AppKit
@preconcurrency import ApplicationServices
import ServiceManagement

@MainActor
final class PermissionService: ObservableObject {
    @Published private(set) var accessibility = false
    @Published private(set) var posting = false
    var ready: Bool { accessibility && posting }
    func refresh() {
        accessibility = AXIsProcessTrusted()
        posting = CGPreflightPostEventAccess()
    }
    func request() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        openSettings()
    }
    func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
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
        enabled = SMAppService.mainApp.status == .enabled
        needsApproval = SMAppService.mainApp.status == .requiresApproval
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
