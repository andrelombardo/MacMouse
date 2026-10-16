import CoreGraphics

public enum SyntheticEvents {
    public static let marker: Int64 = 0x4D_61_63_4D_6F_75_73_65
    public static func keyboard(for shortcut: Shortcut) -> [CGEvent] {
        guard shortcut.isValid,
              let down = CGEvent(keyboardEventSource: nil, virtualKey: shortcut.keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: shortcut.keyCode, keyDown: false) else { return [] }
        var flags = CGEventFlags(rawValue: shortcut.modifiers)
        // Arrow keys are function keys. System shortcuts match this implicit Fn
        // trait; Numeric Pad is a separate modifier and must not be added.
        if (123...126).contains(shortcut.keyCode) { flags.insert(.maskSecondaryFn) }
        for event in [down, up] {
            event.flags = flags
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
