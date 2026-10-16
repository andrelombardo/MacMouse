import AppKit
import Carbon.HIToolbox
import Combine
import SwiftUI

@main
enum MacMouseApp {
    @MainActor static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
        withExtendedLifetime(delegate) {}
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    private let model = AppModel()
    private var window: NSWindow?
    private var statusItem: NSStatusItem?
    private var workspaceObservers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Launch Services normally enforces one instance; handle direct executable launches too.
        if let identifier = Bundle.main.bundleIdentifier,
           let existing = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
            .first(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            existing.activate(options: [])
            NSApp.terminate(nil)
            return
        }
        makeApplicationMenu()
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "MacMouse")
        item.button?.image?.isTemplate = true
        item.button?.toolTip = "MacMouse"
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
        model.start()
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers.append(center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.sleep() }
        })
        workspaceObservers.append(center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.wake() }
        })
        workspaceObservers.append(center.addObserver(forName: NSWorkspace.sessionDidResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.sleep() }
        })
        workspaceObservers.append(center.addObserver(forName: NSWorkspace.sessionDidBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.wake() }
        })
        workspaceObservers.append(center.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.spaceDidChange() }
        })
        let event = NSAppleEventManager.shared().currentAppleEvent
        let loginLaunch = event?.eventID == kAEOpenApplication
            && event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
        if !loginLaunch && !ProcessInfo.processInfo.arguments.contains("--background") { showWindow() }
        runSmokeCaptureIfRequested()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }
    func applicationDidBecomeActive(_ notification: Notification) {
        model.refresh()
        if window?.isVisible == true { model.windowVisible(true) }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) {
        model.stop()
        for observer in workspaceObservers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
    }

    @objc private func showWindow() {
        if window == nil {
            let root = MainView(model: model, devices: model.devices, permissions: model.permissions, login: model.login)
            let controller = NSHostingController(rootView: root)
            let value = NSWindow(contentViewController: controller)
            value.title = "MacMouse"
            value.styleMask = [.titled, .closable, .miniaturizable]
            value.titlebarAppearsTransparent = true
            value.isReleasedWhenClosed = false
            value.delegate = self
            value.center()
            value.setFrameAutosaveName("MacMouse.MainWindow")
            window = value
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
        model.windowVisible(true)
    }
    func windowWillClose(_ notification: Notification) {
        model.windowVisible(false)
        window?.contentViewController = nil
        window = nil
    }
    func windowDidMiniaturize(_ notification: Notification) { model.windowVisible(false) }
    func windowDidDeminiaturize(_ notification: Notification) { model.windowVisible(true) }

    func menuNeedsUpdate(_ menu: NSMenu) {
        model.refresh()
        menu.removeAllItems()
        menu.addItem(withTitle: "Apri MacMouse", action: #selector(showWindow), keyEquivalent: "")
        let active = menu.addItem(withTitle: model.configuration.enabled ? "Disattiva MacMouse" : "Attiva MacMouse",
                                  action: #selector(toggleEnabled), keyEquivalent: "")
        active.state = model.configuration.enabled ? .on : .off
        let login = menu.addItem(withTitle: "Avvia al login", action: #selector(toggleLogin), keyEquivalent: "")
        login.state = model.login.enabled ? .on : .off
        menu.addItem(.separator())
        menu.addItem(withTitle: "Esci da MacMouse", action: #selector(quit), keyEquivalent: "q")
        for item in menu.items { item.target = self }
    }
    @objc private func toggleEnabled() { model.setEnabled(!model.configuration.enabled) }
    @objc private func toggleLogin() { model.login.setEnabled(!model.login.enabled) }
    @objc private func quit() { NSApp.terminate(nil) }

    private func makeApplicationMenu() {
        let main = NSMenu()
        let root = main.addItem(withTitle: "MacMouse", action: nil, keyEquivalent: "")
        let app = NSMenu(title: "MacMouse")
        app.addItem(withTitle: "Informazioni su MacMouse", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        app.addItem(.separator())
        let open = app.addItem(withTitle: "Apri MacMouse", action: #selector(showWindow), keyEquivalent: ",")
        open.target = self
        app.addItem(withTitle: "Nascondi MacMouse", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        app.addItem(.separator())
        app.addItem(withTitle: "Esci da MacMouse", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        root.submenu = app
        let edit = main.addItem(withTitle: "Modifica", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "Modifica")
        for (title, selector, key) in [("Taglia", #selector(NSText.cut(_:)), "x"),
                                        ("Copia", #selector(NSText.copy(_:)), "c"),
                                        ("Incolla", #selector(NSText.paste(_:)), "v"),
                                        ("Seleziona tutto", #selector(NSText.selectAll(_:)), "a")] {
            editMenu.addItem(withTitle: title, action: selector, keyEquivalent: key)
        }
        edit.submenu = editMenu
        let windowRoot = main.addItem(withTitle: "Finestra", action: nil, keyEquivalent: "")
        let windowMenu = NSMenu(title: "Finestra")
        windowMenu.addItem(withTitle: "Chiudi finestra", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenu.addItem(withTitle: "Contrai", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowRoot.submenu = windowMenu
        NSApp.windowsMenu = windowMenu
        NSApp.mainMenu = main
    }

    /// Captures the actual rendered content view without screen recording or synthetic UI.
    private func runSmokeCaptureIfRequested() {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "--smoke-capture"), args.count > index + 1 else { return }
        let path = args[index + 1]
        if args.contains("--dark") { NSApp.appearance = NSAppearance(named: .darkAqua) }
        if args.contains("--light") { NSApp.appearance = NSAppearance(named: .aqua) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
            guard let view = window?.contentView,
                  let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
            view.cacheDisplay(in: view.bounds, to: bitmap)
            if let png = bitmap.representation(using: .png, properties: [:]) { try? png.write(to: URL(fileURLWithPath: path)) }
            let report: [String: Any] = ["version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
                "bundlePath": Bundle.main.bundleURL.path, "system": ProcessInfo.processInfo.operatingSystemVersionString,
                "accessibility": model.permissions.accessibility, "posting": model.permissions.posting,
                "engine": model.status.title, "windowVisible": window?.isVisible == true,
                "mouseNames": model.devices.devices.map(\.name), "physicalHardwareTested": false]
            if let json = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) {
                try? json.write(to: URL(fileURLWithPath: path + ".json"))
            }
        }
    }
}
