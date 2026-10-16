import Foundation

/// A temporary selection, committed only by the confirmation button.
/// Observed numbers are unique candidates, not an input history.
public struct ButtonDetection: Equatable, Sendable {
    public private(set) var candidate: Int?
    public private(set) var phase: MousePhase?
    public private(set) var observedButtons: [Int] = []
    public init() {}

    public mutating func observe(button: Int, phase: MousePhase) {
        guard (2...31).contains(button), phase != .dragged else { return }
        if phase == .down {
            candidate = button
            if !observedButtons.contains(button) { observedButtons.append(button) }
        }
        if candidate == button { self.phase = phase }
    }
    public mutating func select(_ button: Int) {
        guard observedButtons.contains(button) else { return }
        candidate = button
        phase = nil
    }
    public func conflicts(in configuration: Configuration, bindingID: Int) -> Bool {
        guard let candidate else { return false }
        return configuration.bindings.contains { $0.id != bindingID && $0.buttonNumber == candidate }
    }
    @discardableResult public func confirm(in configuration: inout Configuration, bindingID: Int) -> Bool {
        guard let candidate else { return false }
        return configuration.assign(button: candidate, to: bindingID)
    }
}
