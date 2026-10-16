import AppKit
import CoreGraphics
#if SWIFT_PACKAGE
import MacMouseCore
#endif

enum EngineStatus: Equatable, Sendable {
    case stopped, running, permissionRequired, unavailable, suspended
    var title: String {
        switch self {
        case .stopped: "In pausa"
        case .running: "Pronto"
        case .permissionRequired: "Autorizzazione necessaria"
        case .unavailable: "Intercettazione non disponibile"
        case .suspended: "Intercettazione sospesa"
        }
    }
}

struct MouseDiagnostic: Sendable {
    let button: Int
    let event: String
}

struct ButtonObservation: Sendable {
    let button: Int
    let phase: MousePhase
}

/// All tap and router state lives on a dedicated, sleeping CFRunLoop thread.
/// The lock protects only publication of the loop. No lock is taken by the callback.
final class MouseEngine: @unchecked Sendable {
    var onStatus: (@Sendable (EngineStatus) -> Void)?
    var onLearn: (@Sendable (ButtonObservation) -> Void)?
    var onDiagnostic: (@Sendable (MouseDiagnostic) -> Void)?
    var onAction: (@Sendable (ButtonAction) -> Void)?

    private let loopLock = NSLock()
    private var loop: CFRunLoop?
    private var thread: Thread?
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var router = ButtonRouter()
    private var diagnostics = false
    private var recovery = TapRecoveryPolicy()

    func startThread() {
        guard thread == nil else { return }
        let ready = DispatchSemaphore(value: 0)
        let worker = Thread { [self] in
            let current = CFRunLoopGetCurrent()!
            // A Port provides a persistent source even before permissions are granted.
            let port = Port()
            RunLoop.current.add(port, forMode: .default)
            loopLock.withLock { loop = current }
            ready.signal()
            CFRunLoopRun()
            port.invalidate()
            loopLock.withLock { loop = nil }
        }
        worker.name = "MacMouse.Input"
        worker.qualityOfService = .userInteractive
        thread = worker
        worker.start()
        ready.wait()
    }

    private func perform(_ work: @escaping @Sendable () -> Void) {
        guard let current = loopLock.withLock({ loop }) else { return }
        CFRunLoopPerformBlock(current, CFRunLoopMode.defaultMode.rawValue, work)
        CFRunLoopWakeUp(current)
    }

    func configure(_ configuration: Configuration, authorized: Bool, retry: Bool = false) {
        perform { [self] in
            if (!configuration.enabled && !router.learning) || !authorized { flush() }
            router.configuration = configuration
            guard authorized else {
                removeTap()
                onStatus?(.permissionRequired)
                return
            }
            if retry { recovery.reset() }
            guard configuration.enabled || router.learning else {
                // Keep the filter alive to balance any outstanding consumed releases.
                onStatus?(.stopped)
                return
            }
            installTap()
        }
    }

    func learn() {
        perform { [self] in
            flush()
            router.beginLearning()
            installTap()
        }
    }
    func cancelLearning() { perform { [self] in router.cancelLearning() } }
    func setDiagnostics(_ value: Bool) { perform { [self] in diagnostics = value } }
    func interrupt() { perform { [self] in flush() } }
    func sleep() { perform { [self] in flush(); removeTap(); onStatus?(.suspended) } }

    func shutdown() {
        guard loopLock.withLock({ loop != nil }) else { return }
        let finished = DispatchSemaphore(value: 0)
        perform { [self] in
            flush()
            removeTap()
            CFRunLoopStop(CFRunLoopGetCurrent())
            finished.signal()
        }
        _ = finished.wait(timeout: .now() + 1)
    }

    private func installTap() {
        if let tap, CGEvent.tapIsEnabled(tap: tap) {
            onStatus?(router.configuration.enabled ? .running : .stopped)
            return
        }
        removeTap()
        let mask = [CGEventType.otherMouseDown, .otherMouseUp, .otherMouseDragged]
            .reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let newTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                            options: .defaultTap, eventsOfInterest: mask,
                                            callback: { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            let engine = Unmanaged<MouseEngine>.fromOpaque(context).takeUnretainedValue()
            return engine.receive(type: type, event: event)
        }, userInfo: context) else {
            router.cancelLearning()
            onStatus?(.unavailable)
            return
        }
        guard let newSource = CFMachPortCreateRunLoopSource(nil, newTap, 0) else {
            CFMachPortInvalidate(newTap)
            router.cancelLearning()
            onStatus?(.unavailable)
            return
        }
        tap = newTap
        source = newSource
        CFRunLoopAddSource(CFRunLoopGetCurrent(), newSource, .defaultMode)
        CGEvent.tapEnable(tap: newTap, enable: true)
        onStatus?(router.configuration.enabled ? .running : .stopped)
    }

    private func removeTap() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode) }
        tap = nil
        source = nil
    }

    private func receive(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            flush()
            let now = ProcessInfo.processInfo.systemUptime
            if type == .tapDisabledByTimeout, recovery.shouldRecoverTimeout(at: now), let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
                onStatus?(router.configuration.enabled ? .running : .stopped)
            } else {
                removeTap()
                onStatus?(.suspended)
            }
            return Unmanaged.passUnretained(event)
        }
        guard event.getIntegerValueField(.eventSourceUserData) != SyntheticEvents.marker else {
            return Unmanaged.passUnretained(event)
        }
        let phase: MousePhase
        switch type {
        case .otherMouseDown: phase = .down
        case .otherMouseUp: phase = .up
        case .otherMouseDragged: phase = .dragged
        default: return Unmanaged.passUnretained(event)
        }
        let button = Int(event.getIntegerValueField(.mouseEventButtonNumber))
        if diagnostics, phase != .dragged {
            onDiagnostic?(.init(button: button, event: phase == .down ? "otherMouseDown" : "otherMouseUp"))
        }
        let result = router.route(button: button, phase: phase)
        if let number = result.learnedButton { onLearn?(.init(button: number, phase: .down)) }
        else if router.learning, (2...31).contains(button), phase == .up { onLearn?(.init(button: button, phase: .up)) }
        if let action = result.action { onAction?(action) }
        switch result.disposition {
        case .pass: return Unmanaged.passUnretained(event)
        case .suppress: return nil
        case .middle:
            SyntheticEvents.convertToMiddle(event)
            return Unmanaged.passUnretained(event)
        }
    }

    private func flush() {
        if router.interrupt(), let event = SyntheticEvents.middleRelease(at: CGEvent(source: nil)?.location ?? .zero) {
            event.post(tap: .cgSessionEventTap)
        }
    }
}
