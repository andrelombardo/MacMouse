import Testing
@testable import MacMouseCore

@Test func detectionDoesNotSaveUntilConfirmation() {
    var detection = ButtonDetection()
    var configuration = Configuration()
    detection.observe(button: 7, phase: .down)
    detection.observe(button: 7, phase: .up)
    #expect(configuration.bindings[0].buttonNumber == nil)
    #expect(detection.candidate == 7)
    #expect(detection.phase == .up)
    let saved = detection.confirm(in: &configuration, bindingID: 0)
    #expect(saved)
    #expect(configuration.bindings[0].buttonNumber == 7)
}

@Test func repeatedDetectionSelectsLatestAndCanChooseEarlierCandidate() {
    var detection = ButtonDetection()
    for button in [4, 9, 4, 9, 12] {
        detection.observe(button: button, phase: .down)
        detection.observe(button: button, phase: .up)
    }
    #expect(detection.observedButtons == [4, 9, 12])
    #expect(detection.candidate == 12)
    detection.select(9)
    #expect(detection.candidate == 9)
    detection.select(22)
    #expect(detection.candidate == 9)
}

@Test func primaryButtonsAndDragCannotBecomeCandidates() {
    var detection = ButtonDetection()
    for number in [-1, 0, 1, 32] { detection.observe(button: number, phase: .down) }
    detection.observe(button: 5, phase: .dragged)
    detection.observe(button: 6, phase: .up)
    #expect(detection.candidate == nil)
    #expect(detection.observedButtons.isEmpty)
}

@Test func duplicateBindingCannotBeConfirmedOrReplaceExistingMapping() {
    var configuration = Configuration()
    _ = configuration.assign(button: 6, to: 0)
    _ = configuration.assign(button: 8, to: 1)
    let original = configuration
    var detection = ButtonDetection()
    detection.observe(button: 8, phase: .down)
    #expect(detection.conflicts(in: configuration, bindingID: 0))
    let saved = detection.confirm(in: &configuration, bindingID: 0)
    #expect(!saved)
    #expect(configuration == original)
}

@Test func cancellingTemporarySelectionPreservesPersistedMapping() {
    var configuration = Configuration()
    _ = configuration.assign(button: 4, to: 0)
    var detection = ButtonDetection()
    detection.observe(button: 9, phase: .down)
    detection = .init()
    let saved = detection.confirm(in: &configuration, bindingID: 0)
    #expect(!saved)
    #expect(configuration.bindings[0].buttonNumber == 4)
}

@Test func detectionRouterConsumesSeveralClicksUntilCancelled() {
    var router = ButtonRouter()
    _ = router.configuration.assign(button: 4, to: 0)
    router.beginLearning()
    for number in [4, 7, 9] {
        #expect(router.route(button: number, phase: .down) == .init(.suppress, learnedButton: number))
        #expect(router.route(button: number, phase: .up) == .init(.suppress))
        #expect(router.learning)
    }
    _ = router.route(button: 7, phase: .down)
    router.cancelLearning()
    #expect(router.route(button: 7, phase: .up) == .init(.suppress))
    #expect(router.route(button: 7, phase: .down) == .init(.pass))
}

@Test func permissionStateSeparatesAccessibilityFromEventPosting() {
    let missing = PermissionSnapshot(accessibility: false, posting: false)
    let inconsistent = PermissionSnapshot(accessibility: false, posting: true)
    let mouseOnly = PermissionSnapshot(accessibility: true, posting: false)
    let ready = PermissionSnapshot(accessibility: true, posting: true)
    #expect(missing.state == .accessibilityRequired)
    #expect(inconsistent.state == .accessibilityRequired)
    #expect(!inconsistent.canFilterMouse)
    #expect(mouseOnly.state == .postingRequired)
    #expect(mouseOnly.canFilterMouse)
    #expect(!mouseOnly.ready)
    #expect(ready.state == .ready)
    #expect(ready.ready)
}
