import CoreGraphics

public enum SyntheticEvents {
    public static let marker: Int64 = 0x4D_61_63_4D_6F_75_73_65
    public static func keyboard(for shortcut: Shortcut) -> [CGEvent] {
        guard shortcut.isValid, let source = CGEventSource(stateID: .privateState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: false) else { return [] }
        for event in [down, up] {
            event.flags = CGEventFlags(rawValue: shortcut.modifiers)
            event.setIntegerValueField(.eventSourceUserData, value: marker)
            event.setIntegerValueField(.keyboardEventAutorepeat, value: 0)
        }
        return [down, up]
    }
    public static func convertToMiddle(_ event: CGEvent) {
        event.setIntegerValueField(.mouseEventButtonNumber, value: 2)
        event.setIntegerValueField(.eventSourceUserData, value: marker)
    }
    public static func middleRelease(at point: CGPoint) -> CGEvent? {
        guard let event = CGEvent(mouseEventSource: nil, mouseType: .otherMouseUp,
                                  mouseCursorPosition: point, mouseButton: .center) else { return nil }
        event.setIntegerValueField(.eventSourceUserData, value: marker)
        return event
    }
}
