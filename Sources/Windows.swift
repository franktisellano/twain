import AppKit
import ApplicationServices

enum Half {
    case left, right, top, bottom
}

/// The window we're about to move, captured at invocation time.
struct TargetWindow {
    let app: AXUIElement
    let window: AXUIElement
    let title: String

    /// Frame in AppKit screen coordinates (origin bottom-left of primary display).
    var frame: CGRect? {
        guard let pos: CGPoint = axValue(window, kAXPositionAttribute, .cgPoint),
              let size: CGSize = axValue(window, kAXSizeAttribute, .cgSize) else { return nil }
        return flip(CGRect(origin: pos, size: size))
    }

    var screen: NSScreen? {
        guard let frame else { return NSScreen.main }
        var best: NSScreen?
        var bestArea: CGFloat = 0
        for s in NSScreen.screens {
            let i = s.frame.intersection(frame)
            let area = i.isNull ? 0 : i.width * i.height
            if area > bestArea { best = s; bestArea = area }
        }
        return best ?? NSScreen.main
    }

    static func frontmost(of running: NSRunningApplication) -> TargetWindow? {
        let app = AXUIElementCreateApplication(running.processIdentifier)
        // Never let a beach-balling app stall the hot key.
        AXUIElementSetMessagingTimeout(app, 0.25)
        guard let window = axElement(app, kAXFocusedWindowAttribute)
                ?? axElement(app, kAXMainWindowAttribute) else { return nil }
        var raw: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &raw)
        return TargetWindow(app: app, window: window, title: raw as? String ?? "")
    }

    func snap(to half: Half) {
        guard let screen else { return }
        let v = screen.visibleFrame
        var r = v
        switch half {
        case .left:   r.size.width = floor(v.width / 2)
        case .right:  r.size.width = floor(v.width / 2); r.origin.x = v.maxX - r.width
        case .bottom: r.size.height = floor(v.height / 2)
        case .top:    r.size.height = floor(v.height / 2); r.origin.y = v.maxY - r.height
        }
        let ax = flip(r)

        // Apps with "enhanced UI" on (set by assistive tools) animate every AX
        // resize, which is slow and janky. Turn it off for the duration.
        let enhanced = "AXEnhancedUserInterface" as CFString
        var raw: CFTypeRef?
        AXUIElementCopyAttributeValue(app, enhanced, &raw)
        let wasEnhanced = (raw as? Bool) == true
        if wasEnhanced { AXUIElementSetAttributeValue(app, enhanced, kCFBooleanFalse) }

        // Size first so the window fits where it's going, then position, then
        // size again in case the first resize was clamped by the old screen.
        setSize(ax.size)
        setPosition(ax.origin)
        setSize(ax.size)

        if wasEnhanced { AXUIElementSetAttributeValue(app, enhanced, kCFBooleanTrue) }
    }

    private func setPosition(_ p: CGPoint) {
        var p = p
        if let v = AXValueCreate(.cgPoint, &p) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, v)
        }
    }

    private func setSize(_ s: CGSize) {
        var s = s
        if let v = AXValueCreate(.cgSize, &s) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, v)
        }
    }
}

/// Accessibility uses a top-left origin, AppKit bottom-left; the conversion is
/// its own inverse.
private func flip(_ r: CGRect) -> CGRect {
    let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
    return CGRect(x: r.minX, y: primaryHeight - r.maxY, width: r.width, height: r.height)
}

private func axElement(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
    var raw: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &raw) == .success,
          let raw, CFGetTypeID(raw) == AXUIElementGetTypeID() else { return nil }
    return (raw as! AXUIElement)
}

private func axValue<T>(_ element: AXUIElement, _ attribute: String, _ type: AXValueType) -> T? {
    var raw: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &raw) == .success,
          let raw, CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
    let out = UnsafeMutablePointer<T>.allocate(capacity: 1)
    defer { out.deallocate() }
    guard AXValueGetValue(raw as! AXValue, type, out) else { return nil }
    return out.pointee
}
