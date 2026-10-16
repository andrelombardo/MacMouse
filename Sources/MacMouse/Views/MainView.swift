import AppKit
import SwiftUI
import UniformTypeIdentifiers
// Explicit alias selects the public property wrapper, available in CLT and Xcode.
// The macOS 27 State macro plugin is supplied only by full Xcode installations.
typealias ViewState<Value> = SwiftUI.State<Value>
#if SWIFT_PACKAGE
import MacMouseCore
#endif

private enum EditorSheet: Identifiable {
    case shortcut(ShortcutRequest)
    case detection(Int)
    var id: String {
        switch self {
        case .shortcut(let request): "shortcut-\(request.id)"
        case .detection(let id): "detection-\(id)"
        }
    }
}

struct MainView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var devices: DeviceService
    @ObservedObject var permissions: PermissionService
    @ObservedObject var login: LoginService
    @ViewState private var editor: EditorSheet?
    @ViewState private var confirmReset = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 13) {
                Image(systemName: "computermouse").font(.system(size: 27, weight: .light))
                    .frame(width: 38).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(deviceTitle).font(.headline).lineLimit(2)
                    Text(deviceSubtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Label(model.isActive ? "Attivo" : "In pausa", systemImage: model.isActive ? "checkmark.circle.fill" : "pause.circle")
                    .font(.caption).foregroundStyle(model.isActive ? .primary : .secondary)
                    .padding(.horizontal, 10).padding(.vertical, 7).glassEffect(.regular)
            }.padding(.bottom, 16)

            Text("Profilo globale · tutti i mouse")
                .font(.caption).foregroundStyle(.secondary)
                .help("Quartz non identifica il mouse di origine. Le associazioni valgono per tutti i dispositivi che inviano lo stesso numero di pulsante; clic sinistro e destro non vengono intercettati.")
                .padding(.bottom, 20)

            VStack(spacing: 16) {
                ForEach(model.configuration.bindings) { binding in buttonRow(binding) }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.separator.opacity(0.45), lineWidth: 0.5))

            Text(model.configuration.bindings.contains { [.desktopLeft, .desktopRight].contains($0.action.kind) }
                 ? "Per cambiare scrivania servono almeno due spazi in Mission Control."
                 : "Rileva ciascun pulsante e conferma l’associazione.")
                .font(.caption).foregroundStyle(.secondary).padding(.top, 10)

            Divider().padding(.vertical, 20)
            VStack(alignment: .leading, spacing: 14) {
                Toggle("Rimappatura attiva", isOn: Binding(get: { model.configuration.enabled }, set: model.setEnabled))
                    .toggleStyle(.switch).controlSize(.small)
                Toggle("Avvia al login", isOn: Binding(get: { login.enabled }, set: login.setEnabled))
                    .toggleStyle(.switch).controlSize(.small)
                if login.needsApproval {
                    Button("Approva l’avvio in Impostazioni di Sistema") { login.openSettings() }
                        .font(.caption)
                }
            }

            if !permissions.ready {
                VStack(alignment: .leading, spacing: 9) {
                    Label(permissions.title, systemImage: "hand.raised").font(.callout.weight(.medium))
                    Text(permissions.explanation)
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button(permissions.accessibility ? "Consenti invio" : "Apri Impostazioni") { permissions.request() }.buttonStyle(.glass)
                        Button("Verifica") { model.refresh(retry: true) }
                        Button("Mostra app") { permissions.revealApplication() }
                    }.controlSize(.small)
                }.padding(.top, 20)
            } else if model.status == .unavailable || model.status == .suspended {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(model.status.title). Ricontrolla i permessi o riavvia MacMouse.")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button("Riprova") { model.refresh(retry: true) }
                        if model.status == .unavailable && !CGPreflightListenEventAccess() {
                            Button("Consenti Monitoraggio input") {
                                _ = CGRequestListenEventAccess()
                                model.refresh(retry: true)
                            }
                        }
                    }.controlSize(.small)
                }.padding(.top, 16)
            }

            if let message = model.message ?? login.error {
                HStack(alignment: .top, spacing: 8) {
                    Text(message).font(.caption).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button { model.message = nil; login.error = nil } label: { Image(systemName: "xmark") }
                        .buttonStyle(.plain).accessibilityLabel("Chiudi messaggio")
                }.padding(.top, 14)
            }

            HStack {
                Text(model.statusText).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Button(model.diagnosticsVisible ? "Nascondi diagnostica" : "Mostra diagnostica") { model.diagnosticsVisible.toggle() }
                    Button("Autorizzazioni…") { permissions.openSettings() }
                    Divider()
                    Button("Ripristina impostazioni…", role: .destructive) { confirmReset = true }
                } label: { Image(systemName: "gearshape") }
                    .menuStyle(.borderlessButton).fixedSize().help("Preferenze e diagnostica")
                    .accessibilityLabel("Preferenze e diagnostica")
            }.padding(.top, 22)

            if model.diagnosticsVisible { diagnostics.padding(.top, 14) }
        }
        .padding(24)
        .frame(width: 460)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(item: $editor, onDismiss: { model.cancelLearning() }) { sheet in
            switch sheet {
            case .shortcut(let request):
                ShortcutSheet(request: request) { shortcut in
                    model.setAction(.init(request.kind, shortcut: shortcut), id: request.id)
                }
            case .detection(let id):
                ButtonDetectionSheet(bindingID: id, model: model, permissions: permissions)
            }
        }
        .alert("Ripristinare MacMouse?", isPresented: $confirmReset) {
            Button("Annulla", role: .cancel) {}
            Button("Ripristina", role: .destructive) { model.reset() }
        } message: {
            Text("Verranno rimosse le associazioni e le scorciatoie. L’avvio al login verrà disattivato.")
        }
    }

    private var deviceTitle: String {
        if devices.devices.count > 1 { return "\(devices.devices.count) mouse collegati" }
        return devices.devices.first?.name ?? "Il tuo mouse"
    }
    private var deviceSubtitle: String {
        if let device = devices.devices.first {
            return devices.devices.count == 1 ? "Collegato · \(device.transport)" : devices.devices.map(\.name).joined(separator: ", ")
        }
        return "Nessun mouse esterno rilevato"
    }

    private func buttonRow(_ binding: ButtonBinding) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pulsante laterale \(binding.id + 1)").font(.system(size: 13, weight: .medium))
                Button(binding.buttonNumber.map { "Pulsante \($0) · Rileva…" } ?? "Rileva pulsante…") {
                    editor = .detection(binding.id)
                }
                .buttonStyle(.link).font(.caption)
                .accessibilityLabel("Rileva pulsante laterale \(binding.id + 1)")
            }
            Spacer(minLength: 0)
            Menu {
                actionGroup("Navigazione", kinds: [.back, .forward], binding: binding)
                actionGroup("macOS", kinds: [.missionControl, .desktopLeft, .desktopRight, .appExpose, .showDesktop, .switchApplication, .launchpad], binding: binding)
                actionGroup("Applicazioni", kinds: [.openApplication, .closeWindow, .hideApplication, .switchWindow], binding: binding)
                actionGroup("Tastiera", kinds: [.shortcut], binding: binding)
                actionGroup("Pulsante", kinds: [.original, .disabled, .middleClick], binding: binding)
            } label: {
                Text(actionTitle(binding.action)).lineLimit(1).frame(width: 133, alignment: .trailing)
            }.controlSize(.small)
                .accessibilityLabel("Azione del pulsante laterale \(binding.id + 1)")
            Menu {
                Button("Rileva pulsante…") { editor = .detection(binding.id) }
                if binding.buttonNumber != nil { Button("Rimuovi associazione") { model.clearButton(id: binding.id) } }
                if binding.action.kind.supportsShortcutOverride {
                    Divider()
                    Button("\(binding.action.shortcut == nil ? "Registra" : "Modifica") scorciatoia…") {
                        editor = .shortcut(.init(id: binding.id, kind: binding.action.kind, current: binding.action.shortcut))
                    }
                    if binding.action.shortcut != nil {
                        Button("Elimina scorciatoia") {
                            let kind: ActionKind = [.shortcut, .launchpad].contains(binding.action.kind) ? .original : binding.action.kind
                            model.setAction(.init(kind), id: binding.id)
                        }
                    }
                }
            } label: { Image(systemName: "ellipsis") }
                .menuStyle(.borderlessButton).fixedSize()
                .accessibilityLabel("Opzioni del pulsante laterale \(binding.id + 1)")
                .help("Rileva pulsante e altre opzioni")
        }
    }

    private func actionGroup(_ title: String, kinds: [ActionKind], binding: ButtonBinding) -> some View {
        Section(title) {
            ForEach(kinds, id: \.self) { kind in
                Button {
                    select(kind, binding: binding)
                } label: {
                    if binding.action.kind == kind { Label(kind.title, systemImage: "checkmark") }
                    else { Text(kind.title) }
                }
            }
        }
    }
    private func actionTitle(_ action: ButtonAction) -> String {
        if action.kind == .shortcut { return action.shortcut?.display ?? "Registra scorciatoia…" }
        if action.kind == .openApplication, let path = action.applicationPath {
            return URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        }
        return action.kind.title.replacingOccurrences(of: "…", with: "")
    }
    private func select(_ kind: ActionKind, binding: ButtonBinding) {
        if kind == .shortcut || kind == .launchpad {
            editor = .shortcut(.init(id: binding.id, kind: kind, current: binding.action.kind == kind ? binding.action.shortcut : nil))
        } else if kind == .openApplication {
            let panel = NSOpenPanel()
            panel.title = "Scegli un’applicazione"
            panel.prompt = "Scegli"
            panel.allowedContentTypes = [.applicationBundle]
            panel.directoryURL = URL(fileURLWithPath: "/Applications")
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            if panel.runModal() == .OK, let url = panel.url {
                model.setAction(.init(kind, applicationPath: url.path), id: binding.id)
            }
        } else { model.setAction(.init(kind), id: binding.id) }
    }

    private var diagnostics: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Diagnostica").font(.caption.weight(.semibold))
            Text(model.lastDiagnostic.map { "Pulsante \($0.button) · \($0.event)" } ?? "Premi un pulsante aggiuntivo del mouse.")
                .font(.system(.caption, design: .monospaced))
            if let shortcut = model.lastShortcut {
                Text("Combinazione inviata: \(shortcut.display)").font(.system(.caption, design: .monospaced))
            }
            HStack {
                Button("Prova pulsante 1") { model.testAction(id: 0) }
                Button("Prova pulsante 2") { model.testAction(id: 1) }
            }.controlSize(.small)
            Text("Cambi scrivania osservati: \(model.spaceChanges)").font(.caption)
            ForEach(devices.devices) { device in
                Text(String(format: "%@ · VID %04X · PID %04X", device.name, device.vendorID, device.productID)).font(.caption)
            }
            Text("Solo l’ultimo evento mouse, in memoria. Nessuna provenienza HID attribuita. Le azioni macOS richiedono scorciatoie di sistema abilitate; puoi personalizzarle dal menu del pulsante.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Text("Controllo del dispositivo: \(permissions.accessibility ? "consentito" : "non riconosciuto") · Invio eventi: \(permissions.posting ? "consentito" : "non riconosciuto")")
                .font(.caption).foregroundStyle(.secondary)
            Text(Bundle.main.bundleURL.path).font(.caption2).foregroundStyle(.secondary)
            Text("MacMouse \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "") · Beta · profilo globale")
                .font(.caption2).foregroundStyle(.secondary)
        }.textSelection(.enabled)
    }
}
