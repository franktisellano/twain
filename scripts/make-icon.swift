// Renders Resources/AppIcon.icns. Run: swift scripts/make-icon.swift
import AppKit

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(px) / 1024

    // Standard macOS icon grid: 824pt squircle centred in a 1024 canvas.
    let plate = NSRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
    let platePath = NSBezierPath(roundedRect: plate, xRadius: 185 * s, yRadius: 185 * s)
    NSGradient(colors: [NSColor(red: 0.16, green: 0.17, blue: 0.22, alpha: 1),
                        NSColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1)])!
        .draw(in: platePath, angle: -90)

    // A screen, left half lit.
    let screen = NSRect(x: 250 * s, y: 310 * s, width: 524 * s, height: 404 * s)
    let screenPath = NSBezierPath(roundedRect: screen, xRadius: 56 * s, yRadius: 56 * s)
    NSColor(white: 1, alpha: 0.10).setFill()
    screenPath.fill()

    NSGraphicsContext.saveGraphicsState()
    screenPath.addClip()
    let half = NSRect(x: screen.minX, y: screen.minY, width: screen.width / 2, height: screen.height)
    NSGradient(colors: [NSColor(red: 0.35, green: 0.72, blue: 1.0, alpha: 1),
                        NSColor(red: 0.16, green: 0.47, blue: 0.98, alpha: 1)])!
        .draw(in: half, angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    NSColor(white: 1, alpha: 0.55).setStroke()
    screenPath.lineWidth = 14 * s
    screenPath.stroke()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
let iconset = fm.temporaryDirectory.appendingPathComponent("twain-\(UUID().uuidString).iconset")
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try render(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try render(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try p.run()
p.waitUntilExit()
try? fm.removeItem(at: iconset)
exit(p.terminationStatus)
