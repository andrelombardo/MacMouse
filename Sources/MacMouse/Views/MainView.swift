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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 13) {
                Image(systemName: "computermouse").font(.system(size: 27, weight: .light))
                    .frame(width: 38).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(deviceTitle).font(.headline).lineLimit(2)
                    Text(deviceSubtitle).font(.caption).foregroundStyle(.secondary)
                        .lineLimit(2).help(deviceSubtitle)
                }
                Spacer(minLength: 8)
                HStack(spacing: 5) {
                    Circle().fill(model.isActive ? Color.green : Color.secondary)
                        .frame(width: 6, height: 6).accessibilityHidden(true)
                    Text(model.isActive ? "Attivo" : "In pausa")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.padding(.bottom, 20)

            VStack(spacing: 16) {
                ForEach(model.configuration.bindings) { binding in buttonRow(binding) }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.separator.opacity(0.45), lineWidth: 0.5))

            Divider().padding(.vertical, 20)
            VStack(alignment: .leading, spacing: 14) {
                settingRow("MacMouse attivo", isOn: Binding(get: { model.configuration.enabled }, set: model.setEnabled))
                settingRow("Inverti scorrimento del mouse", isOn: Binding(
                    get: { model.configuration.reverseMouseScrolling }, set: model.setReverseMouseScrolling))
                    .help("Solo la rotella. Lascia attivo lo scorrimento naturale in macOS per il trackpad.")
                settingRow("Avvia al login", isOn: Binding(get: { login.enabled }, set: login.setEnabled))
                settingRow("Mostra icona nella barra dei menu", isOn: Binding(
                    get: { model.configuration.showMenuBarIcon }, set: model.setShowMenuBarIcon))
                    .help("Puoi riaprire MacMouse da Applicazioni anche con l’icona nascosta.")
                if login.needsApproval {
                    Button("Approva l’avvio nelle Impostazioni…") { login.openSettings() }
                        .buttonStyle(.link).font(.caption)
                }
            }
            .toggleStyle(.switch).controlSize(.small)

            Group {
                if permissions.ready {
                    Text("Accessibilità consentita").foregroundStyle(.secondary)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Button("Apri le impostazioni") { permissions.request() }
                            .buttonStyle(.link)
                        Text("per abilitare le accessibilità").foregroundStyle(.secondary)
                    }
                }
            }
            .font(.caption).padding(.top, 20)

            if model.status == .unavailable || model.status == .suspended {
                HStack {
                    Text(model.status.title).foregroundStyle(.secondary)
                    Spacer()
                    Button("Riprova") { model.refresh(retry: true) }.buttonStyle(.link)
                }.font(.caption).padding(.top, 10)
                if model.status == .unavailable && !CGPreflightListenEventAccess() {
                    Button("Consenti Monitoraggio input…") {
                        _ = CGRequestListenEventAccess()
                        model.refresh(retry: true)
                    }.buttonStyle(.link).font(.caption).padding(.top, 8)
                }
            }

            if let message = model.message ?? login.error {
                HStack(alignment: .top, spacing: 8) {
                    Text(message).font(.caption).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button {
                        model.message = nil
                        login.error = nil
                    } label: { Image(systemName: "xmark") }
                        .buttonStyle(.plain).accessibilityLabel("Chiudi messaggio")
                }.padding(.top, 14)
            }
        }
        .padding(24)
        .frame(width: 460)
        .background(Color(nsColor: .textBackgroundColor))
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
    }

    private var deviceTitle: String {
        if devices.devices.count > 1 { return "\(devices.devices.count) mouse collegati" }
        return devices.devices.first?.name ?? "Il tuo mouse"
    }
    private var deviceSubtitle: String {
        if devices.devices.isEmpty { return "Nessun mouse esterno rilevato" }
        if let device = devices.devices.first, devices.devices.count == 1 {
            return device.model ?? "Modello non disponibile"
        }
        return devices.devices.map { "\($0.name): \($0.model ?? "Modello non disponibile")" }
            .joined(separator: "\n")
    }

    private func settingRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Text(title).accessibilityHidden(true)
            Spacer(minLength: 0)
            Toggle(title, isOn: isOn).labelsHidden().fixedSize()
        }
    }

    private func buttonRow(_ binding: ButtonBinding) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pulsante laterale \(binding.id + 1)").font(.system(size: 13, weight: .medium))
                Text(binding.buttonNumber.map { "Pulsante \($0)" } ?? "Non associato")
                    .font(.caption).foregroundStyle(.secondary)
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
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                .accessibilityLabel("Opzioni del pulsante laterale \(binding.id + 1)")
                .help("Opzioni del pulsante")
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

}
