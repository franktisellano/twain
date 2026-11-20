import AppKit

/// The tiny "what am I about to move" popover. Built once at launch and only
/// re-laid-out and ordered in/out afterwards, with no animation and no
/// Auto Layout, so showing it costs well under a frame.
final class HUD {
    private let panel: NSPanel
    private let icon = NSImageView()
    private let name = NSTextField(labelWithString: "")
    private let title = NSTextField(labelWithString: "")

    private let pad: CGFloat = 12
    private let iconSize: CGFloat = 36
    private let gap: CGFloat = 10
    private let maxText: CGFloat = 340

    init() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 200, height: 60),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.appearance = NSAppearance(named: .vibrantDark)

        let fx = NSVisualEffectView(frame: panel.contentLayoutRect)
        fx.material = .hudWindow
        fx.state = .active
        fx.blendingMode = .behindWindow
        fx.wantsLayer = true
        fx.layer?.cornerRadius = 16
        fx.layer?.cornerCurve = .continuous
        fx.layer?.masksToBounds = true
        fx.autoresizingMask = [.width, .height]
        panel.contentView = fx

        icon.imageScaling = .scaleProportionallyUpOrDown
        name.font = .systemFont(ofSize: 14, weight: .semibold)
        name.textColor = .labelColor
        name.lineBreakMode = .byTruncatingTail
        title.font = .systemFont(ofSize: 12)
        title.textColor = .secondaryLabelColor
        title.lineBreakMode = .byTruncatingMiddle
        for v in [icon, name, title] { fx.addSubview(v) }
    }

    var isVisible: Bool { panel.isVisible }

    func show(app: NSRunningApplication, windowTitle: String, over frame: CGRect?, on screen: NSScreen?) {
        let appName = app.localizedName ?? ""
        icon.image = app.icon
        name.stringValue = appName
        let showTitle = !windowTitle.isEmpty && windowTitle != appName
        title.stringValue = showTitle ? windowTitle : ""
        title.isHidden = !showTitle

        let nameSize = name.cell!.cellSize
        let titleSize = showTitle ? title.cell!.cellSize : .zero
        let textW = ceil(min(max(nameSize.width, titleSize.width), maxText))
        let height = iconSize + pad * 2
        let width = pad + iconSize + gap + textW + pad + 4

        icon.frame = NSRect(x: pad, y: pad, width: iconSize, height: iconSize)
        let textX = pad + iconSize + gap
        if showTitle {
            let block = nameSize.height + titleSize.height
            let base = (height - block) / 2
            title.frame = NSRect(x: textX, y: base, width: textW, height: titleSize.height)
            name.frame = NSRect(x: textX, y: base + titleSize.height, width: textW, height: nameSize.height)
        } else {
            name.frame = NSRect(x: textX, y: (height - nameSize.height) / 2, width: textW, height: nameSize.height)
        }

        // Centre on the window being moved, kept fully on its screen.
        let bounds = (screen ?? NSScreen.main)?.visibleFrame ?? .zero
        let anchor = frame.map { $0.intersection(bounds) }.flatMap { $0.isNull || $0.isEmpty ? nil : $0 } ?? bounds
        var origin = CGPoint(x: anchor.midX - width / 2, y: anchor.midY - height / 2)
        origin.x = max(bounds.minX + 8, min(origin.x, bounds.maxX - width - 8))
        origin.y = max(bounds.minY + 8, min(origin.y, bounds.maxY - height - 8))

        panel.setFrame(NSRect(x: round(origin.x), y: round(origin.y), width: width, height: height), display: true)
        panel.invalidateShadow()
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }
}
