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
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let model = AppModel()
    private var window: NSWindow?
    private var statusItem: NSStatusItem?
    private var menuVisibility: AnyCancellable?
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
        menuVisibility = model.$configuration
            .map(\.showMenuBarIcon)
            .removeDuplicates()
            .sink { [weak self] visible in self?.setMenuBarIconVisible(visible) }
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
        let event = NSAppleEventManager.shared().currentAppleEvent
        let loginLaunch = event?.eventID == kAEOpenApplication
            && event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
        if !loginLaunch && !ProcessInfo.processInfo.arguments.contains("--background") { showWindow() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }
    func applicationDidBecomeActive(_ notification: Notification) {
        model.refresh()
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

    private func setMenuBarIconVisible(_ visible: Bool) {
        guard visible else {
            if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
            statusItem = nil
            return
        }
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "MacMouse")
        item.button?.image?.isTemplate = true
        item.button?.toolTip = "MacMouse"
        let menu = NSMenu()
        menu.addItem(withTitle: "Apri MacMouse", action: #selector(showWindow), keyEquivalent: "")
        menu.addItem(withTitle: "Esci da MacMouse", action: #selector(quit), keyEquivalent: "q")
        for entry in menu.items { entry.target = self }
        item.menu = menu
        statusItem = item
    }
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

}
