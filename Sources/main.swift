import AppKit
import ApplicationServices
import Carbon.HIToolbox

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let hud = HUD()
    private let setup = SetupWindow()
    private var statusItem: NSStatusItem!
    private var loginMenuItem: NSMenuItem!

    private var target: TargetWindow?
    private var sessionKeys: [UInt32] = []
    private var mouseMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()

        let registered = HotKeys.shared.register(key: kVK_Space,
                                                 modifiers: controlKey | optionKey | cmdKey) { [unowned self] in
            self.target == nil ? self.begin() : self.end()
        }
        if registered == nil {
            let alert = NSAlert()
            alert.messageText = "⌃⌥⌘Space is already taken"
            alert.informativeText = "Another app has claimed the shortcut. Quit it and relaunch Twain."
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [unowned self] _ in self.end() }

        if !AXIsProcessTrusted() { setup.show() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        setup.show()
        return false
    }

    // MARK: - Session: hot key pressed → HUD up, ⌘arrows armed

    private func begin() {
        guard AXIsProcessTrusted() else { setup.show(); return }
        guard let app = NSWorkspace.shared.frontmostApplication,
              let window = TargetWindow.frontmost(of: app) else { NSSound.beep(); return }
        target = window

        // Arm the arrows before drawing anything so a fast follow-up keystroke
        // is never missed.
        let arrows: [(Int, Half)] = [(kVK_LeftArrow, .left), (kVK_RightArrow, .right),
                                     (kVK_UpArrow, .top), (kVK_DownArrow, .bottom)]
        for (key, half) in arrows {
            if let id = HotKeys.shared.register(key: key, modifiers: cmdKey, { [unowned self] in
                let w = self.target
                self.end()
                w?.snap(to: half)
            }) { sessionKeys.append(id) }
        }
        if let id = HotKeys.shared.register(key: kVK_Escape, modifiers: 0, { [unowned self] in self.end() }) {
            sessionKeys.append(id)
        }

        hud.show(app: app, windowTitle: window.title, over: window.frame, on: window.screen)

        mouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [unowned self] _ in self.end() }
    }

    private func end() {
        guard target != nil else { return }
        target = nil
        sessionKeys.forEach(HotKeys.shared.unregister)
        sessionKeys.removeAll()
        if let mouseMonitor { NSEvent.removeMonitor(mouseMonitor) }
        mouseMonitor = nil
        hud.hide()
    }

    // MARK: - Menu bar

    private func buildMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let image = NSImage(systemSymbolName: "rectangle.lefthalf.filled", accessibilityDescription: "Twain")
        image?.isTemplate = true
        statusItem.button?.image = image

        let menu = NSMenu()
        menu.delegate = self
        let hint = NSMenuItem(title: "⌃⌥⌘Space, then ⌘ + arrow", action: nil, keyEquivalent: "")
        hint.isEnabled = false
        menu.addItem(hint)
        menu.addItem(.separator())
        loginMenuItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
        loginMenuItem.target = self
        menu.addItem(loginMenuItem)
        let setupItem = NSMenuItem(title: "Setup…", action: #selector(showSetup), keyEquivalent: "")
        setupItem.target = self
        menu.addItem(setupItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Twain", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        loginMenuItem.state = LoginItem.isEnabled ? .on : .off
    }

    @objc private func toggleLogin() { LoginItem.set(!LoginItem.isEnabled) }
    @objc private func showSetup() { setup.show() }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
