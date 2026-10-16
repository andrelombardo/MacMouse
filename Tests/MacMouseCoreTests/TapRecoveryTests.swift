import Testing
@testable import MacMouseCore

@Test func tapRecoveryIsBoundedAndExpiresAfterOneMinute() {
    var policy = TapRecoveryPolicy()
    let results = [policy.shouldRecoverTimeout(at: 0), policy.shouldRecoverTimeout(at: 1),
                   policy.shouldRecoverTimeout(at: 2), policy.shouldRecoverTimeout(at: 3),
                   policy.shouldRecoverTimeout(at: 64)]
    #expect(results == [true, true, false, false, true])
}
@Test func explicitRetryResetsTheRecoveryBudget() {
    var policy = TapRecoveryPolicy()
    for _ in 0..<3 { _ = policy.shouldRecoverTimeout(at: 0) }
    policy.reset()
    let recovered = policy.shouldRecoverTimeout(at: 1)
    #expect(recovered)
}
