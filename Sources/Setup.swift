import AppKit
import ApplicationServices
import ServiceManagement

enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Twain: login item change failed: \(error.localizedDescription)")
        }
    }
}

/// First-run window: walks through granting Accessibility access and flips to
/// a "you're set" state the moment the permission lands.
final class SetupWindow: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var timer: Timer?
    private var trusted = false

    private let status = NSTextField(labelWithString: "")
    private let body = NSTextField(wrappingLabelWithString: "")
    private let primary = NSButton(title: "", target: nil, action: nil)
    private let login = NSButton(checkboxWithTitle: "Launch Twain at login", target: nil, action: nil)

    func show() {
        if window == nil { build() }
        refresh(force: true)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.refresh() }
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    private func build() {
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 10),
                         styleMask: [.titled, .closable, .fullSizeContentView],
                         backing: .buffered, defer: false)
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.isMovableByWindowBackground = true
        w.isReleasedWhenClosed = false
        w.delegate = self

        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 72).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let heading = NSTextField(labelWithString: "Twain")
        heading.font = .systemFont(ofSize: 22, weight: .bold)

        status.font = .systemFont(ofSize: 13, weight: .medium)
        body.font = .systemFont(ofSize: 13)
        body.textColor = .secondaryLabelColor
        body.alignment = .center
        body.preferredMaxLayoutWidth = 340

        primary.bezelStyle = .rounded
        primary.controlSize = .large
        primary.keyEquivalent = "\r"
        primary.target = self
        primary.action = #selector(primaryAction)

        login.target = self
        login.action = #selector(toggleLogin)

        let stack = NSStackView(views: [icon, heading, status, body, login, primary])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.setCustomSpacing(4, after: icon)
        stack.setCustomSpacing(16, after: body)
        stack.edgeInsets = NSEdgeInsets(top: 36, left: 40, bottom: 28, right: 40)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            content.widthAnchor.constraint(equalToConstant: 420),
        ])
        w.contentView = content
        window = w
    }

    private func refresh(force: Bool = false) {
        let now = AXIsProcessTrusted()
        guard force || now != trusted else { return }
        trusted = now
        login.state = LoginItem.isEnabled ? .on : .off
        if trusted {
            status.stringValue = "✓  Accessibility access granted"
            status.textColor = .systemGreen
            body.stringValue = "Press ⌃⌥⌘Space, then ⌘← ⌘→ ⌘↑ ⌘↓ to send the active window to that half of the screen. Esc cancels.\n\nTwain lives in the menu bar."
            primary.title = "Done"
            login.isHidden = false
        } else {
            status.stringValue = "Accessibility access needed"
            status.textColor = .systemOrange
            body.stringValue = "macOS only lets apps move other apps' windows with your permission. Turn on Twain under Privacy & Security → Accessibility; this window updates as soon as you do."
            primary.title = "Open Accessibility Settings"
            login.isHidden = true
        }
    }

    @objc private func primaryAction() {
        if trusted {
            window?.close()
            return
        }
        // Adds Twain to the Accessibility list (and shows the system prompt
        // the first time), then jumps straight to the right settings pane.
        let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func toggleLogin() {
        LoginItem.set(login.state == .on)
        login.state = LoginItem.isEnabled ? .on : .off
    }

    func windowWillClose(_ notification: Notification) {
        timer?.invalidate()
        timer = nil
    }
}
