import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import MacMouseCore
#endif

struct ShortcutRequest: Identifiable {
    let id: Int
    let kind: ActionKind
    let current: Shortcut?
}

struct ShortcutSheet: View {
    let request: ShortcutRequest
    let onSave: (Shortcut) -> Void
    @Environment(\.dismiss) private var dismiss
    @ViewState private var shortcut: Shortcut?
    init(request: ShortcutRequest, onSave: @escaping (Shortcut) -> Void) {
        self.request = request
        self.onSave = onSave
        _shortcut = State(initialValue: request.current)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Registra scorciatoia").font(.headline)
            Text(request.kind == .launchpad
                 ? "Premi la combinazione che hai assegnato ad Applicazioni o Launchpad nelle impostazioni della tastiera."
                 : "Premi una combinazione di tasti, anche con ⌘, ⇧, ⌥ o ⌃. Esc annulla.")
                .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            ShortcutCapture(shortcut: $shortcut, cancel: { dismiss() })
                .frame(height: 66)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    Text(shortcut?.display ?? "Premi i tasti…").font(.system(size: 22, weight: .medium))
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            Text("Viene salvata solo questa combinazione. Nessuna cronologia della tastiera.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Button("Cancella", action: { shortcut = nil }).disabled(shortcut == nil)
                Spacer()
                Button("Annulla") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Salva") {
                    if let shortcut { onSave(shortcut); dismiss() }
                }.disabled(shortcut == nil).buttonStyle(.glassProminent)
            }
        }.padding(24).frame(width: 400)
    }
}

private struct ShortcutCapture: NSViewRepresentable {
    @Binding var shortcut: Shortcut?
    let cancel: () -> Void
    func makeNSView(context: Context) -> CaptureView {
        let view = CaptureView()
        view.onShortcut = { shortcut = $0 }
        view.onCancel = cancel
        return view
    }
    func updateNSView(_ view: CaptureView, context: Context) {
        view.onShortcut = { shortcut = $0 }
        view.setAccessibilityLabel(shortcut?.display ?? "Premi una scorciatoia")
    }
}

private final class CaptureView: NSView {
    var onShortcut: ((Shortcut) -> Void)?
    var onCancel: (() -> Void)?
    override var acceptsFirstResponder: Bool { true }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setAccessibilityElement(true)
        setAccessibilityRole(.textField)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.window?.makeFirstResponder(self)
        }
    }
    override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(self) }
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard window?.firstResponder === self else { return false }
        capture(event)
        return true
    }
    override func keyDown(with event: NSEvent) { capture(event) }
    private func capture(_ event: NSEvent) {
        guard !event.isARepeat else { return }
        if event.keyCode == 53 { onCancel?(); return }
        let labels: [UInt16: String] = [
            36: "↩", 48: "⇥", 49: "Spazio", 51: "⌫", 76: "⌤", 117: "⌦",
            123: "←", 124: "→", 125: "↓", 126: "↑", 115: "↖", 119: "↘", 116: "⇞", 121: "⇟",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7",
            100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12", 105: "F13",
            107: "F14", 113: "F15", 106: "F16", 64: "F17", 79: "F18", 80: "F19", 90: "F20"
        ]
        let label = labels[event.keyCode] ?? event.charactersIgnoringModifiers?.uppercased() ?? ""
        let shortcut = Shortcut(keyCode: event.keyCode,
                                modifiers: UInt64(event.modifierFlags.rawValue), keyLabel: label)
        if shortcut.isValid { onShortcut?(shortcut) }
    }
}
