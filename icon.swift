// Renders AppIcon.icns: swift icon.swift
import AppKit

let S: CGFloat = 1024
let img = NSImage(size: NSSize(width: S, height: S), flipped: false) { _ in
    let ctx = NSGraphicsContext.current!.cgContext
    let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
    let squircle = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
    NSGradient(colors: [NSColor(white: 0.13, alpha: 1), NSColor(white: 0.02, alpha: 1)])!.draw(in: squircle, angle: -90)
    squircle.addClip()

    let strokes: [(CGPoint, CGPoint)] = [
        (CGPoint(x: 250, y: 560), CGPoint(x: 400, y: 790)),
        (CGPoint(x: 300, y: 260), CGPoint(x: 560, y: 720)),
        (CGPoint(x: 510, y: 260), CGPoint(x: 730, y: 650)),
    ]
    let path = CGMutablePath()
    for (a, b) in strokes { path.move(to: a); path.addLine(to: b) }
    ctx.setLineCap(.round)

    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 90, color: NSColor(red: 0.1, green: 0.4, blue: 1, alpha: 1).cgColor)
    ctx.addPath(path); ctx.setLineWidth(118); ctx.setStrokeColor(NSColor(red: 0.05, green: 0.35, blue: 1, alpha: 1).cgColor); ctx.strokePath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(path); ctx.setLineWidth(118); ctx.replacePathWithStrokedPath(); ctx.clip()
    let blue = CGGradient(colorsSpace: nil, colors: [NSColor(red: 0.0, green: 0.55, blue: 1, alpha: 1).cgColor,
                                                     NSColor(red: 0.05, green: 0.3, blue: 0.95, alpha: 1).cgColor] as CFArray, locations: nil)!
    ctx.drawLinearGradient(blue, start: CGPoint(x: 0, y: 250), end: CGPoint(x: 0, y: 800), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()

    let c = CGPoint(x: 720, y: 360), r: CGFloat = 125
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 60, color: NSColor(white: 1, alpha: 0.55).cgColor)
    NSColor.white.setFill()
    NSBezierPath(ovalIn: NSRect(x: c.x - r - 18, y: c.y - r - 18, width: 2 * (r + 18), height: 2 * (r + 18))).fill()
    ctx.restoreGState()
    NSGradient(colors: [NSColor(red: 0.15, green: 0.85, blue: 0.3, alpha: 1), NSColor(red: 0.0, green: 0.62, blue: 0.15, alpha: 1)])!
        .draw(in: NSBezierPath(ovalIn: NSRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), angle: -90)
    let check = NSBezierPath()
    check.lineWidth = 34; check.lineCapStyle = .round; check.lineJoinStyle = .round
    check.move(to: NSPoint(x: c.x - 62, y: c.y + 2)); check.line(to: NSPoint(x: c.x - 18, y: c.y - 42)); check.line(to: NSPoint(x: c.x + 64, y: c.y + 48))
    NSColor.white.setStroke(); check.stroke()
    return true
}

let set = URL(fileURLWithPath: "build/AppIcon.iconset")
try? FileManager.default.removeItem(at: set)
try! FileManager.default.createDirectory(at: set, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let px = base * scale
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
                                   hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        img.draw(in: NSRect(x: 0, y: 0, width: px, height: px))
        NSGraphicsContext.restoreGraphicsState()
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try! rep.representation(using: .png, properties: [:])!.write(to: set.appendingPathComponent(name))
    }
}
