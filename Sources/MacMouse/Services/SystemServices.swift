import AppKit
@preconcurrency import ApplicationServices
import ServiceManagement
#if SWIFT_PACKAGE
import MacMouseCore
#endif

@MainActor
final class PermissionService: ObservableObject {
    @Published private(set) var snapshot = PermissionSnapshot(accessibility: false, posting: false)
    var accessibility: Bool { snapshot.accessibility }
    var posting: Bool { snapshot.posting }
    var ready: Bool { snapshot.ready }
    var canFilterMouse: Bool { snapshot.canFilterMouse }
    var title: String {
        switch snapshot.state {
        case .accessibilityRequired: "Consenti il controllo del dispositivo"
        case .postingRequired: "Consenti l’invio delle scorciatoie"
        case .ready: "Autorizzazioni pronte"
        }
    }
    var explanation: String {
        switch snapshot.state {
        case .accessibilityRequired:
            "In Privacy e sicurezza → Controllo del dispositivo e accesso ai dati abilita questa copia di MacMouse. Se è già attiva, macOS potrebbe conservare il consenso a una versione precedente: riavvia il Mac dopo aver riaggiunto l’app."
        case .postingRequired:
            "Il controllo del dispositivo è autorizzato. Manca il consenso per inviare le scorciatoie: premi Consenti invio, poi verifica."
        case .ready: "MacMouse può rilevare i pulsanti e inviare le scorciatoie."
        }
    }
    func refresh() {
        let current = PermissionSnapshot(accessibility: AXIsProcessTrusted(), posting: CGPreflightPostEventAccess())
        if current != snapshot { snapshot = current }
    }
    func request() {
        if snapshot.state == .postingRequired {
            _ = CGRequestPostEventAccess()
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
    func revealApplication() { NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL]) }
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
