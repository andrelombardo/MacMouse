import CoreGraphics

public enum MouseScrolling {
    /// Reverse line-based wheels in place. Continuous scrolling, including
    /// trackpad gestures and momentum, passes through byte-for-byte unchanged.
    @discardableResult public static func reverseWheel(_ event: CGEvent, enabled: Bool) -> Bool {
        guard enabled, event.type == .scrollWheel,
              event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0,
              event.getIntegerValueField(.scrollWheelEventScrollPhase) == 0,
              event.getIntegerValueField(.scrollWheelEventMomentumPhase) == 0,
              event.getIntegerValueField(.eventSourceUserData) != SyntheticEvents.marker else { return false }
        reverseAxis(event, line: .scrollWheelEventDeltaAxis1,
                    point: .scrollWheelEventPointDeltaAxis1, fixed: .scrollWheelEventFixedPtDeltaAxis1)
        reverseAxis(event, line: .scrollWheelEventDeltaAxis2,
                    point: .scrollWheelEventPointDeltaAxis2, fixed: .scrollWheelEventFixedPtDeltaAxis2)
        return true
    }

    private static func reverseAxis(_ event: CGEvent, line: CGEventField, point: CGEventField, fixed: CGEventField) {
        // Setting the line delta also recalculates point/fixed values in Quartz.
        // Read all three first, then restore the original precision and speed.
        let lines = event.getIntegerValueField(line)
        let points = event.getIntegerValueField(point)
        let fraction = event.getDoubleValueField(fixed)
        event.setIntegerValueField(line, value: lines == .min ? .max : -lines)
        event.setIntegerValueField(point, value: points == .min ? .max : -points)
        event.setDoubleValueField(fixed, value: -fraction)
    }
}
