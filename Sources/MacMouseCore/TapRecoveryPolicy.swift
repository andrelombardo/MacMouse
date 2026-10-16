import Foundation

public struct TapRecoveryPolicy: Sendable {
    private var failures: [TimeInterval] = []
    public init() {}
    public mutating func reset() { failures.removeAll() }
    public mutating func shouldRecoverTimeout(at now: TimeInterval) -> Bool {
        failures = failures.filter { now - $0 < 60 }
        failures.append(now)
        return failures.count <= 2
    }
}
