// Renders docs/screenshot.png, the illustration at the top of the README.
// Run: swift scripts/make-screenshot.swift
//
// Drawn rather than captured so it is reproducible and free of anything that
// happens to be on someone's desktop. The HUD matches Sources/HUD.swift
// (16pt corners, 12pt padding, 36pt icon, 14pt semibold name, 12pt title).
import AppKit

let W: CGFloat = 960, H: CGFloat = 600, scale: CGFloat = 2
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W * scale), pixelsHigh: Int(H * scale),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: W, height: H)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}
func rounded(_ r: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius)
}
func withShadow(blur: CGFloat, y: CGFloat, alpha: CGFloat, _ body: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let s = NSShadow()
    s.shadowBlurRadius = blur
    s.shadowOffset = NSSize(width: 0, height: -y)
    s.shadowColor = NSColor(white: 0, alpha: alpha)
    s.set()
    body()
    NSGraphicsContext.restoreGraphicsState()
}
func text(_ s: String, _ font: NSFont, _ color: NSColor) -> NSAttributedString {
    NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color])
}

// MARK: Wallpaper

let full = NSRect(x: 0, y: 0, width: W, height: H)
NSGradient(colors: [rgb(22, 24, 64), rgb(14, 70, 96)])!.draw(in: full, angle: 35)
for (color, center, radius) in [(rgb(236, 92, 140, 0.45), NSPoint(x: 0.75, y: 0.8), 0.9),
                                (rgb(80, 160, 255, 0.40), NSPoint(x: -0.8, y: -0.6), 1.0),
                                (rgb(255, 180, 90, 0.25), NSPoint(x: 0.9, y: -0.9), 0.7)] {
    let g = NSGradient(colors: [color, color.withAlphaComponent(0)])!
    let c = NSPoint(x: W * (0.5 + center.x * 0.5), y: H * (0.5 + center.y * 0.5))
    g.draw(fromCenter: c, radius: 0, toCenter: c, radius: W * radius, options: [])
}

// MARK: Menu bar

let barH: CGFloat = 24
rgb(255, 255, 255, 0.16).setFill()
NSRect(x: 0, y: H - barH, width: W, height: barH).fill()
let barFont = NSFont.systemFont(ofSize: 13)
text("Editor", .boldSystemFont(ofSize: 13), .white).draw(at: NSPoint(x: 16, y: H - 19))
var mx: CGFloat = 76
for item in ["File", "Edit", "View", "Window"] {
    let t = text(item, barFont, .white)
    t.draw(at: NSPoint(x: mx, y: H - 19))
    mx += t.size().width + 18
}
let clock = text("Thu 9:41 AM", barFont, .white)
clock.draw(at: NSPoint(x: W - 16 - clock.size().width, y: H - 19))
let symbolConfig = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
    .applying(.init(paletteColors: [.white]))
if let sym = NSImage(systemSymbolName: "rectangle.lefthalf.filled", accessibilityDescription: nil)?
    .withSymbolConfiguration(symbolConfig) {
    let x = W - 16 - clock.size().width - 30
    sym.draw(in: NSRect(x: x, y: H - barH + (barH - sym.size.height) / 2,
                        width: sym.size.width, height: sym.size.height))
}

// MARK: Destination: the left half of the screen

let visible = NSRect(x: 0, y: 0, width: W, height: H - barH)
let target = NSRect(x: visible.minX, y: visible.minY, width: visible.width / 2, height: visible.height)
    .insetBy(dx: 10, dy: 10)
let targetPath = rounded(target, 14)
rgb(110, 180, 255, 0.14).setFill()
targetPath.fill()
targetPath.lineWidth = 2
targetPath.setLineDash([8, 6], count: 2, phase: 0)
rgb(160, 205, 255, 0.75).setStroke()
targetPath.stroke()

// MARK: App icon for the window being moved (a plain document, drawn here)

func drawDocIcon(in r: NSRect) {
    let plate = rounded(r.insetBy(dx: r.width * 0.06, dy: r.width * 0.06), r.width * 0.22)
    NSGradient(colors: [rgb(255, 196, 70), rgb(246, 140, 40)])!.draw(in: plate, angle: -90)
    let page = NSRect(x: r.minX + r.width * 0.28, y: r.minY + r.height * 0.2,
                      width: r.width * 0.44, height: r.height * 0.6)
    NSColor.white.setFill()
    rounded(page, r.width * 0.05).fill()
    rgb(246, 140, 40, 0.8).setFill()
    for i in 0..<4 {
        let w = page.width * (i == 3 ? 0.4 : 0.64)
        rounded(NSRect(x: page.minX + page.width * 0.18, y: page.maxY - page.height * (0.25 + CGFloat(i) * 0.17),
                       width: w, height: max(1, r.height * 0.04)), 1).fill()
    }
}

// MARK: The frontmost window

let win = NSRect(x: 330, y: 160, width: 470, height: 310)
let winPath = rounded(win, 12)
withShadow(blur: 40, y: 18, alpha: 0.45) {
    rgb(250, 250, 252).setFill()
    winPath.fill()
}
NSGraphicsContext.saveGraphicsState()
winPath.addClip()
let titleH: CGFloat = 38
rgb(236, 236, 240).setFill()
NSRect(x: win.minX, y: win.maxY - titleH, width: win.width, height: titleH).fill()
rgb(0, 0, 0, 0.08).setFill()
NSRect(x: win.minX, y: win.maxY - titleH, width: win.width, height: 1).fill()
for (i, c) in [rgb(255, 95, 87), rgb(254, 188, 46), rgb(40, 200, 64)].enumerated() {
    c.setFill()
    NSBezierPath(ovalIn: NSRect(x: win.minX + 16 + CGFloat(i) * 20, y: win.maxY - titleH / 2 - 6,
                                width: 12, height: 12)).fill()
}
let winTitle = text("draft.md", .systemFont(ofSize: 13, weight: .semibold), rgb(60, 60, 67))
winTitle.draw(at: NSPoint(x: win.midX - winTitle.size().width / 2, y: win.maxY - titleH / 2 - 8))

// Sidebar and placeholder text lines.
let side = NSRect(x: win.minX, y: win.minY, width: 130, height: win.height - titleH)
rgb(243, 243, 246).setFill()
side.fill()
rgb(0, 0, 0, 0.06).setFill()
NSRect(x: side.maxX, y: side.minY, width: 1, height: side.height).fill()
for i in 0..<6 {
    (i == 1 ? rgb(0, 122, 255, 0.18) : NSColor.clear).setFill()
    let row = NSRect(x: side.minX + 10, y: side.maxY - 34 - CGFloat(i) * 28, width: side.width - 20, height: 22)
    rounded(row, 6).fill()
    rgb(60, 60, 67, 0.35).setFill()
    rounded(NSRect(x: row.minX + 10, y: row.midY - 3, width: [70, 54, 82, 60, 48, 74][i], height: 6), 3).fill()
}
let body = NSRect(x: side.maxX + 26, y: win.minY + 24, width: win.maxX - side.maxX - 52, height: win.height - titleH - 48)
rgb(28, 28, 30, 0.75).setFill()
rounded(NSRect(x: body.minX, y: body.maxY - 14, width: body.width * 0.5, height: 12), 4).fill()
let widths: [CGFloat] = [0.95, 0.88, 0.92, 0.6, 0, 0.9, 0.97, 0.84, 0.7, 0, 0.93, 0.5]
for (i, f) in widths.enumerated() where f > 0 {
    rgb(60, 60, 67, 0.22).setFill()
    rounded(NSRect(x: body.minX, y: body.maxY - 44 - CGFloat(i) * 17, width: body.width * f, height: 7), 3.5).fill()
}
NSGraphicsContext.restoreGraphicsState()
rgb(0, 0, 0, 0.12).setStroke()
winPath.lineWidth = 0.5
winPath.stroke()

// MARK: HUD, centred on the window (same geometry as Sources/HUD.swift)

let pad: CGFloat = 12, iconSize: CGFloat = 36, gap: CGFloat = 10
let hudName = text("Editor", .systemFont(ofSize: 14, weight: .semibold), .white)
let hudTitle = text("draft.md", .systemFont(ofSize: 12), NSColor(white: 1, alpha: 0.6))
let textW = ceil(max(hudName.size().width, hudTitle.size().width))
let hudH = iconSize + pad * 2
let hudW = pad + iconSize + gap + textW + pad + 4
let hud = NSRect(x: round(win.midX - hudW / 2), y: round(win.midY - hudH / 2), width: hudW, height: hudH)
let hudPath = rounded(hud, 16)
withShadow(blur: 24, y: 10, alpha: 0.4) {
    rgb(38, 38, 44, 0.92).setFill()
    hudPath.fill()
}
rgb(255, 255, 255, 0.12).setStroke()
hudPath.lineWidth = 1
hudPath.stroke()
drawDocIcon(in: NSRect(x: hud.minX + pad, y: hud.minY + pad, width: iconSize, height: iconSize))
let block = hudName.size().height + hudTitle.size().height
let base = hud.minY + (hudH - block) / 2
let textX = hud.minX + pad + iconSize + gap
hudTitle.draw(at: NSPoint(x: textX, y: base))
hudName.draw(at: NSPoint(x: textX, y: base + hudTitle.size().height))

// MARK: Arrow from the window towards its destination

let arrow = NSBezierPath()
let tail = NSPoint(x: win.minX - 14, y: win.midY), head = NSPoint(x: target.midX - 40, y: win.midY)
arrow.move(to: tail)
arrow.line(to: NSPoint(x: head.x + 10, y: head.y))
arrow.lineWidth = 4
arrow.lineCapStyle = .round
rgb(160, 205, 255, 0.95).setStroke()
arrow.stroke()
let tip = NSBezierPath()
tip.move(to: head)
tip.line(to: NSPoint(x: head.x + 16, y: head.y + 10))
tip.line(to: NSPoint(x: head.x + 16, y: head.y - 10))
tip.close()
rgb(160, 205, 255, 0.95).setFill()
tip.fill()

// MARK: Keystrokes

func keycap(_ label: String, at x: CGFloat, y: CGFloat, minWidth: CGFloat = 34) -> CGFloat {
    let t = text(label, .systemFont(ofSize: 16, weight: .medium), rgb(40, 40, 46))
    let w = max(minWidth, t.size().width + 22)
    let r = NSRect(x: x, y: y, width: w, height: 34)
    withShadow(blur: 0, y: 2, alpha: 0.35) {
        rgb(248, 248, 250).setFill()
        rounded(r, 7).fill()
    }
    t.draw(at: NSPoint(x: r.midX - t.size().width / 2, y: r.midY - t.size().height / 2))
    return w
}
let groups: [[String]] = [["⌃", "⌥", "⌘", "Space"], ["⌘", "←"]]
let capGap: CGFloat = 6, sepW: CGFloat = 54
func capsWidth(_ g: [String]) -> CGFloat {
    g.map { max(34, text($0, .systemFont(ofSize: 16, weight: .medium), .black).size().width + 22) }
        .reduce(0, +) + capGap * CGFloat(g.count - 1)
}
let rowW = groups.map(capsWidth).reduce(0, +) + sepW
let pill = NSRect(x: W / 2 - rowW / 2 - 18, y: 46, width: rowW + 36, height: 58)
withShadow(blur: 20, y: 6, alpha: 0.3) {
    rgb(20, 20, 26, 0.6).setFill()
    rounded(pill, 29).fill()
}
var kx = pill.minX + 18
for (gi, g) in groups.enumerated() {
    for k in g { kx += keycap(k, at: kx, y: pill.minY + 12) + capGap }
    kx -= capGap
    if gi == 0 {
        let then = text("then", .systemFont(ofSize: 13, weight: .medium), NSColor(white: 1, alpha: 0.75))
        then.draw(at: NSPoint(x: kx + sepW / 2 - then.size().width / 2, y: pill.midY - then.size().height / 2))
        kx += sepW
    }
}

NSGraphicsContext.restoreGraphicsState()
try FileManager.default.createDirectory(atPath: "docs", withIntermediateDirectories: true)
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "docs/screenshot.png"))
print("wrote docs/screenshot.png")
