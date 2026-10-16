import CoreGraphics
import Testing
@testable import MacMouseCore

@Test func keyboardEventsAlwaysPairAndCarryModifiersAndMarker() {
    for keyCode: UInt16 in [0, 48, 103, 122, 126] {
        let shortcut = Shortcut(keyCode: keyCode, modifiers: 0x1E0000, keyLabel: "Tasto")
        let events = SyntheticEvents.keyboard(for: shortcut)
        #expect(events.count == 2)
        #expect(events.map(\.type) == [.keyDown, .keyUp])
        for event in events {
            #expect(event.getIntegerValueField(.keyboardEventKeycode) == keyCode)
            #expect(event.flags.rawValue & Shortcut.modifierMask == 0x1E0000)
            #expect(event.getIntegerValueField(.eventSourceUserData) == SyntheticEvents.marker)
            #expect(event.getIntegerValueField(.keyboardEventAutorepeat) == 0)
        }
    }
}
@Test func arrowShortcutsMatchNativeFunctionKeyTraits() {
    for key: UInt16 in [123, 124, 125, 126] {
        let shortcut = Shortcut(keyCode: key, modifiers: 0x40000, keyLabel: "Freccia")
        let events = SyntheticEvents.keyboard(for: shortcut)
        #expect(events.map(\.type) == [.keyDown, .keyUp])
        // Matches the Control + function-key binding reported by HIToolbox.
        #expect(events.allSatisfy { $0.flags == [.maskControl, .maskSecondaryFn] })
        #expect(events.allSatisfy { !$0.flags.contains(.maskNumericPad) })
    }
    let plain = SyntheticEvents.keyboard(for: .init(keyCode: 0, modifiers: 0, keyLabel: "A"))
    #expect(plain.map(\.type) == [.keyDown, .keyUp])
    #expect(plain.allSatisfy { $0.flags.isEmpty })
}
@Test func invalidShortcutProducesNoPartialChord() {
    #expect(SyntheticEvents.keyboard(for: .init(keyCode: 55, modifiers: 0, keyLabel: "⌘")).isEmpty)
}
@Test func middleConversionPreservesPhaseAndPosition() throws {
    for phase in [CGEventType.otherMouseDown, .otherMouseDragged, .otherMouseUp] {
        let event = try #require(CGEvent(mouseEventSource: nil, mouseType: phase,
                                         mouseCursorPosition: CGPoint(x: 123, y: 456),
                                         mouseButton: CGMouseButton(rawValue: 7)!))
        SyntheticEvents.convertToMiddle(event)
        #expect(event.type == phase)
        #expect(event.location == CGPoint(x: 123, y: 456))
        #expect(event.getIntegerValueField(.mouseEventButtonNumber) == 2)
        #expect(event.getIntegerValueField(.eventSourceUserData) == SyntheticEvents.marker)
    }
}
@Test func interruptedMiddleClickGeneratesOnlyRelease() throws {
    let event = try #require(SyntheticEvents.middleRelease(at: CGPoint(x: 21, y: 32)))
    #expect(event.type == .otherMouseUp)
    #expect(event.getIntegerValueField(.mouseEventButtonNumber) == 2)
    #expect(event.location == CGPoint(x: 21, y: 32))
    #expect(event.getIntegerValueField(.eventSourceUserData) == SyntheticEvents.marker)
}
