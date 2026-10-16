import Foundation

public enum MousePhase: Equatable, Sendable { case down, up, dragged }
public enum EventDisposition: Equatable, Sendable { case pass, suppress, middle }
public struct RoutingResult: Equatable, Sendable {
    public var disposition: EventDisposition
    public var action: ButtonAction?
    public var learnedButton: Int?
    public init(_ disposition: EventDisposition, action: ButtonAction? = nil, learnedButton: Int? = nil) {
        self.disposition = disposition
        self.action = action
        self.learnedButton = learnedButton
    }
}

/// A deterministic press/release state machine. Its owner serializes all access.
/// No keyboard state, device attribution or input history is kept here.
public struct ButtonRouter: Sendable {
    public var configuration = Configuration()
    public private(set) var learning = false
    private var pressed: [Int: EventDisposition] = [:]
    public init() {}
    public mutating func beginLearning() { learning = true }
    public mutating func cancelLearning() { learning = false }

    public mutating func route(button: Int, phase: MousePhase, synthetic: Bool = false) -> RoutingResult {
        guard !synthetic, (2...31).contains(button) else { return .init(.pass) }
        if phase == .up {
            return .init(pressed.removeValue(forKey: button) ?? .pass)
        }
        if phase == .dragged { return .init(pressed[button] ?? .pass) }
        if let existing = pressed[button] {
            // Duplicate downs must not repeat a shortcut or another button's middle down.
            return .init(existing == .pass ? .pass : .suppress)
        }
        if learning {
            pressed[button] = .suppress
            return .init(.suppress, learnedButton: button)
        }
        guard configuration.enabled,
              let action = configuration.bindings.first(where: { $0.buttonNumber == button })?.action,
              action.isConfigured else {
            pressed[button] = .pass
            return .init(.pass)
        }
        switch action.kind {
        case .original:
            pressed[button] = .pass
            return .init(.pass)
        case .middleClick:
            // One virtual middle button cannot have two simultaneous owners.
            let result: EventDisposition = pressed.values.contains(.middle) ? .suppress : .middle
            pressed[button] = result
            return .init(result)
        case .disabled:
            pressed[button] = .suppress
            return .init(.suppress)
        default:
            pressed[button] = .suppress
            return .init(.suppress, action: action)
        }
    }

    /// Flush a virtual middle press on disable, sleep, disconnect or tap failure.
    /// Consume outstanding remapped releases; preserve releases for original downs.
    @discardableResult public mutating func interrupt() -> Bool {
        learning = false
        let releaseMiddle = pressed.values.contains(.middle)
        for (button, disposition) in pressed where disposition != .pass { pressed[button] = .suppress }
        return releaseMiddle
    }
}
