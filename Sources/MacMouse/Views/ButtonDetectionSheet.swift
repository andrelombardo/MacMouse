import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import MacMouseCore
#endif

struct ButtonDetectionSheet: View {
    let bindingID: Int
    @ObservedObject var model: AppModel
    @ObservedObject var permissions: PermissionService
    @Environment(\.dismiss) private var dismiss

    private var conflict: Bool { model.detection.conflicts(in: model.configuration, bindingID: bindingID) }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rileva pulsante laterale \(bindingID + 1)").font(.headline)
            Text("Porta il puntatore nel riquadro e premi un tasto laterale. Puoi provarne altri prima di confermare.")
                .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            LocalMouseCapture(value: captureDescription) { number, phase in
                model.observeButton(.init(button: number, phase: phase))
            }
            .frame(height: 112)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "computermouse").font(.system(size: 25, weight: .light))
                    Text(model.detection.candidate.map { "Pulsante \($0)" } ?? "Premi un pulsante…")
                        .font(.system(size: 21, weight: .medium)).monospacedDigit()
                    if let phase = model.detection.phase {
                        Text(phase == .down ? "Premuto" : "Rilasciato").font(.caption).foregroundStyle(.secondary)
                    }
                }.allowsHitTesting(false).accessibilityHidden(true)
            }

            if !model.detection.observedButtons.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        Text("Rilevati:").font(.caption).foregroundStyle(.secondary)
                        ForEach(model.detection.observedButtons, id: \.self) { number in
                            Button("\(number)") { model.selectDetectedButton(number) }
                                .buttonStyle(.bordered)
                                .tint(model.detection.candidate == number ? .accentColor : .secondary)
                                .accessibilityLabel("Seleziona pulsante \(number)")
                        }
                    }
                }.scrollIndicators(.hidden).controlSize(.small)
            }
            if conflict {
                Label("Questo pulsante è già associato all’altra riga. Premi un altro tasto o rimuovi prima quell’associazione.", systemImage: "exclamationmark.circle")
                    .font(.caption).fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Clic sinistro e destro restano invariati. L’associazione viene salvata solo con Conferma.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            if !permissions.canFilterMouse {
                Text("Puoi rilevare nel riquadro anche adesso. Per attivare le azioni, concedi il controllo del dispositivo nelle impostazioni di macOS.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            } else if model.status == .unavailable || model.status == .suspended {
                Text("Il rilevamento globale è sospeso. Il riquadro continua a ricevere i pulsanti dentro questa finestra.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button("Azzera") { model.clearDetection() }.disabled(model.detection.candidate == nil)
                Spacer()
                Button("Annulla") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Conferma") {
                    if model.confirmLearning() { dismiss() }
                }
                .buttonStyle(.glassProminent).keyboardShortcut(.defaultAction)
                .disabled(model.detection.candidate == nil || conflict)
            }
        }
        .padding(24).frame(width: 410)
        .onAppear { model.beginLearning(id: bindingID) }
        .onDisappear { model.cancelLearning() }
        .onChange(of: model.learningID) { _, id in if id == nil { dismiss() } }
    }
    private var captureDescription: String {
        guard let number = model.detection.candidate else { return "In attesa di un pulsante" }
        let state = model.detection.phase == .down ? "premuto" : "rilasciato"
        return "Pulsante \(number), \(state)"
    }
}

/// Local AppKit events work without global monitoring permission. Only the capture
/// area handles extra mouse buttons; keyboard and primary clicks are untouched.
private struct LocalMouseCapture: NSViewRepresentable {
    let value: String
    let receive: (Int, MousePhase) -> Void
    func makeNSView(context: Context) -> MouseCaptureView {
        let view = MouseCaptureView()
        view.receive = receive
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.group)
        view.setAccessibilityLabel("Area di rilevamento del mouse")
        view.setAccessibilityHelp("Porta il puntatore in quest’area e premi un pulsante laterale.")
        return view
    }
    func updateNSView(_ view: MouseCaptureView, context: Context) {
        view.receive = receive
        if view.accessibilityValue() as? String != value {
            view.setAccessibilityValue(value)
            NSAccessibility.post(element: view, notification: .valueChanged)
        }
    }
}

private final class MouseCaptureView: NSView {
    var receive: ((Int, MousePhase) -> Void)?
    override func otherMouseDown(with event: NSEvent) { receive?(event.buttonNumber, .down) }
    override func otherMouseUp(with event: NSEvent) { receive?(event.buttonNumber, .up) }
    override func otherMouseDragged(with event: NSEvent) {}
}
