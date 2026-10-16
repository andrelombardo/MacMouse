import Foundation
import Testing
@testable import MacMouseCore

private func configured(_ first: ActionKind = .back, _ second: ActionKind = .forward) -> ButtonRouter {
    var router = ButtonRouter()
    _ = router.configuration.assign(button: 7, to: 0)
    _ = router.configuration.assign(button: 12, to: 1)
    router.configuration.bindings[0].action = .init(first)
    router.configuration.bindings[1].action = .init(second)
    return router
}

@Test func bothButtonsHaveIndependentActionsAndBalancedReleases() {
    var router = configured()
    #expect(router.route(button: 7, phase: .down) == .init(.suppress, action: .init(.back)))
    #expect(router.route(button: 12, phase: .down) == .init(.suppress, action: .init(.forward)))
    #expect(router.route(button: 7, phase: .down) == .init(.suppress))
    #expect(router.route(button: 12, phase: .up) == .init(.suppress))
    #expect(router.route(button: 7, phase: .up) == .init(.suppress))
    #expect(router.route(button: 7, phase: .up) == .init(.pass))
}

@Test func desktopActionsSurviveReloadAndWorkWithoutRecordedShortcuts() throws {
    let configuration = configured(.desktopLeft, .desktopRight).configuration
    let restored = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration))
    #expect(restored.isValid)
    var router = ButtonRouter()
    router.configuration = restored
    for binding in restored.bindings {
        let button = try #require(binding.buttonNumber)
        #expect(binding.action.shortcut == nil)
        #expect(router.route(button: button, phase: .down) == .init(.suppress, action: binding.action))
        #expect(router.route(button: button, phase: .down) == .init(.suppress))
        #expect(router.route(button: button, phase: .up) == .init(.suppress))
    }
}

@Test func leftRightAndUnknownButtonsPassEvenWhileLearning() {
    var router = configured()
    router.beginLearning()
    for button in [0, 1, -1, 32] {
        for phase in [MousePhase.down, .up, .dragged] { #expect(router.route(button: button, phase: phase) == .init(.pass)) }
    }
    #expect(router.learning)
    router.cancelLearning()
    #expect(router.route(button: 29, phase: .down) == .init(.pass))
    #expect(router.route(button: 29, phase: .up) == .init(.pass))
}

@Test func learningUsesActualNumberAndConsumesWholeClick() {
    var router = configured()
    router.beginLearning()
    #expect(router.route(button: 17, phase: .down) == .init(.suppress, learnedButton: 17))
    #expect(router.learning)
    #expect(router.route(button: 17, phase: .up) == .init(.suppress))
    #expect(router.route(button: 17, phase: .down) == .init(.suppress, learnedButton: 17))
    _ = router.route(button: 17, phase: .up)
    router.cancelLearning()
    #expect(router.route(button: 18, phase: .down) == .init(.pass))
}

@Test func learningWorksWithRemappingDisabledAndIgnoresSyntheticInput() {
    var router = configured()
    router.configuration.enabled = false
    router.beginLearning()
    #expect(router.route(button: 7, phase: .down, synthetic: true) == .init(.pass))
    #expect(router.learning)
    #expect(router.route(button: 7, phase: .down) == .init(.suppress, learnedButton: 7))
}

@Test func changingConfigurationDuringPressDoesNotLeakRelease() {
    var router = configured()
    _ = router.route(button: 7, phase: .down)
    router.configuration.bindings[0].action = .init(.original)
    #expect(router.route(button: 7, phase: .up) == .init(.suppress))
    #expect(router.route(button: 7, phase: .down) == .init(.pass))
    router.configuration.bindings[0].action = .init(.disabled)
    #expect(router.route(button: 7, phase: .up) == .init(.pass))
    #expect(router.route(button: 7, phase: .down) == .init(.suppress))
    #expect(router.route(button: 7, phase: .up) == .init(.suppress))
}

@Test func disablingTakesEffectOnNextPressAndBalancesCurrentPress() {
    var router = configured()
    _ = router.route(button: 7, phase: .down)
    router.configuration.enabled = false
    let released = router.interrupt()
    #expect(!released)
    #expect(router.route(button: 7, phase: .up) == .init(.suppress))
    #expect(router.route(button: 7, phase: .down) == .init(.pass))
    #expect(router.route(button: 7, phase: .up) == .init(.pass))
    router.configuration.enabled = true
    #expect(router.route(button: 7, phase: .down).action == .init(.back))
}

@Test func middleClickSupportsDragAndFlushesOnce() {
    var router = configured(.middleClick, .middleClick)
    #expect(router.route(button: 7, phase: .down) == .init(.middle))
    #expect(router.route(button: 7, phase: .dragged) == .init(.middle))
    #expect(router.route(button: 12, phase: .down) == .init(.suppress))
    #expect(router.route(button: 12, phase: .up) == .init(.suppress))
    let releases = [router.interrupt(), router.interrupt()]
    #expect(releases == [true, false])
    #expect(router.route(button: 7, phase: .up) == .init(.suppress))
    #expect(router.route(button: 7, phase: .down) == .init(.middle))
    #expect(router.route(button: 7, phase: .up) == .init(.middle))
}

@Test func interruptedOriginalPressStillReleases() {
    var router = configured(.original)
    #expect(router.route(button: 7, phase: .down) == .init(.pass))
    router.configuration.enabled = false
    router.interrupt()
    #expect(router.route(button: 7, phase: .up) == .init(.pass))
}

@Test func syntheticPressDoesNotChangeHeldPhysicalButton() {
    var router = configured()
    _ = router.route(button: 7, phase: .down)
    #expect(router.route(button: 7, phase: .up, synthetic: true) == .init(.pass))
    #expect(router.route(button: 7, phase: .up) == .init(.suppress))
}

@Test func incompleteActionsLeaveButtonUsable() {
    for kind in [ActionKind.shortcut, .openApplication, .launchpad] {
        var router = configured(kind)
        #expect(router.route(button: 7, phase: .down) == .init(.pass))
        #expect(router.route(button: 7, phase: .up) == .init(.pass))
    }
}

@Test func longHoldAndRepeatedDownDoNotRepeatAction() {
    var router = configured()
    #expect(router.route(button: 7, phase: .down).action != nil)
    for _ in 0..<1000 {
        #expect(router.route(button: 7, phase: .down).action == nil)
        #expect(router.route(button: 7, phase: .dragged).action == nil)
    }
    #expect(router.route(button: 7, phase: .up).action == nil)
}

@Test func manyPressReleaseCyclesLeaveNoStaleState() {
    var router = configured(.middleClick)
    for _ in 0..<10000 {
        #expect(router.route(button: 7, phase: .down).disposition == .middle)
        #expect(router.route(button: 7, phase: .up).disposition == .middle)
    }
    let released = router.interrupt()
    #expect(!released)
}
