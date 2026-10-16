import AppKit
import Combine
#if SWIFT_PACKAGE
import MacMouseCore
#endif

@MainActor
final class AppModel: ObservableObject {
    let devices = DeviceService()
    let permissions = PermissionService()
    let login = LoginService()
    private let store = PreferencesStore()
    private let engine = MouseEngine()
    private let executor = ActionExecutor()
    @Published private(set) var configuration: Configuration
    @Published private(set) var status: EngineStatus = .stopped
    @Published private(set) var learningID: Int?
    @Published private(set) var lastDiagnostic: MouseDiagnostic?
    @Published var message: String?
    @Published var diagnosticsVisible = false {
        didSet {
            engine.setDiagnostics(diagnosticsVisible)
            if !diagnosticsVisible { lastDiagnostic = nil }
        }
    }
    private var learnTimeout: Timer?
    private var permissionTimer: Timer?
    private var suspended = false

    init() {
        let loaded = store.load()
        configuration = loaded.configuration
        if loaded.recovered { message = "Le impostazioni non erano leggibili. Sono stati caricati i valori iniziali; rileva di nuovo i pulsanti." }
    }
    var isActive: Bool { configuration.enabled && status == .running }
    var statusText: String {
        if status == .running && configuration.bindings.allSatisfy({ $0.buttonNumber == nil }) { return "Rileva i pulsanti per iniziare" }
        return status.title
    }
    func start() {
        engine.onStatus = { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.status = status
                if [.unavailable, .suspended, .permissionRequired].contains(status) { self.cancelLearning() }
            }
        }
        engine.onLearn = { [weak self] number in Task { @MainActor [weak self] in self?.learned(number) } }
        engine.onDiagnostic = { [weak self] event in
            Task { @MainActor [weak self] in
                if self?.diagnosticsVisible == true { self?.lastDiagnostic = event }
            }
        }
        engine.onAction = { [weak self] action in
            Task { @MainActor [weak self] in
                guard let self, self.configuration.enabled, !self.suspended else { return }
                self.executor.execute(action)
            }
        }
        executor.onError = { [weak self] text in self?.message = text }
        devices.onDisconnect = { [weak self] in
            self?.executor.cancelPending()
            self?.engine.interrupt()
            self?.cancelLearning()
        }
        engine.startThread()
        devices.start()
        refresh()
    }
    func refresh(retry: Bool = false) {
        permissions.refresh()
        login.refresh()
        if !suspended { engine.configure(configuration, authorized: permissions.ready, retry: retry) }
    }
    func windowVisible(_ visible: Bool) {
        permissionTimer?.invalidate()
        permissionTimer = nil
        if visible {
            refresh()
            if !permissions.ready {
                permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                    MainActor.assumeIsolated {
                        guard let self else { return }
                        self.refresh()
                        if self.permissions.ready { self.permissionTimer?.invalidate(); self.permissionTimer = nil }
                    }
                }
            }
        } else {
            cancelLearning()
            diagnosticsVisible = false
        }
    }
    func setEnabled(_ value: Bool) {
        executor.cancelPending()
        cancelLearning()
        configuration.enabled = value
        persist()
    }
    func setAction(_ action: ButtonAction, id: Int) {
        executor.cancelPending()
        guard let index = configuration.bindings.firstIndex(where: { $0.id == id }) else { return }
        configuration.bindings[index].action = action
        persist()
    }
    func clearButton(id: Int) {
        cancelLearning()
        guard let index = configuration.bindings.firstIndex(where: { $0.id == id }) else { return }
        configuration.bindings[index].buttonNumber = nil
        engine.interrupt()
        persist()
    }
    func beginLearning(id: Int) {
        refresh(retry: true)
        guard permissions.ready else { message = "Concedi Accessibilità prima di rilevare il pulsante."; return }
        cancelLearning()
        learningID = id
        engine.learn()
        learnTimeout = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard self?.learningID != nil else { return }
                self?.cancelLearning()
                self?.message = "Nessun pulsante ricevuto. Riprova premendo un pulsante laterale."
            }
        }
    }
    func cancelLearning() {
        learningID = nil
        learnTimeout?.invalidate()
        learnTimeout = nil
        engine.cancelLearning()
    }
    private func learned(_ number: Int) {
        guard let id = learningID else { return }
        cancelLearning()
        if configuration.assign(button: number, to: id) { persist() }
        else { message = "Il pulsante \(number) è già associato all’altra riga. Rimuovi prima quell’associazione." }
    }
    func reset() {
        executor.cancelPending()
        cancelLearning()
        engine.interrupt()
        configuration = .init()
        persist()
        // Login registration is system state, separate from button configuration.
        if login.enabled || login.needsApproval { login.setEnabled(false) }
    }
    private func persist() {
        guard store.save(configuration) else { message = "Impossibile salvare le impostazioni."; return }
        refresh()
    }
    func sleep() { executor.cancelPending(); suspended = true; cancelLearning(); engine.sleep() }
    func wake() { suspended = false; refresh(retry: true) }
    func stop() {
        executor.cancelPending()
        permissionTimer?.invalidate()
        cancelLearning()
        devices.stop()
        engine.shutdown()
    }
}
