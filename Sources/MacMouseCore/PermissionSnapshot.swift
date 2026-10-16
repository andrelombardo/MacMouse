public struct PermissionSnapshot: Equatable, Sendable {
    public enum State: Equatable, Sendable { case accessibilityRequired, postingRequired, ready }
    public let accessibility: Bool
    public let posting: Bool
    public init(accessibility: Bool, posting: Bool) {
        self.accessibility = accessibility
        self.posting = posting
    }
    public var canFilterMouse: Bool { accessibility }
    public var ready: Bool { accessibility && posting }
    public var state: State {
        if !accessibility { return .accessibilityRequired }
        return posting ? .ready : .postingRequired
    }
}
