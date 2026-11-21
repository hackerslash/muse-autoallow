// Renders AppIcon.icns from icon-source.png: swift icon.swift && iconutil -c icns build/AppIcon.iconset -o AppIcon.icns
import AppKit

let S: CGFloat = 1024
let src = NSImage(contentsOfFile: "icon-source.png")!
let img = NSImage(size: NSSize(width: S, height: S), flipped: false) { _ in
    let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
    let squircle = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
    NSColor.black.setFill()
    squircle.fill()
    squircle.addClip()
    // Source is 3:2; take a square around the mark (out-of-bounds stays black).
    let crop = NSRect(x: 150, y: -100, width: 1224, height: 1224)
    src.draw(in: tile.insetBy(dx: 40, dy: 40), from: crop, operation: .sourceOver, fraction: 1)

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

// Menu bar template: blue pixels of the mark become alpha; the status badge is drawn in code.
let mw = 88, mh = 64
let mask = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: mw, pixelsHigh: mh, bitsPerSample: 8, samplesPerPixel: 4,
                            hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: mw * 4, bitsPerPixel: 32)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: mask)
src.draw(in: NSRect(x: 0, y: 0, width: mw, height: mh), from: NSRect(x: 180, y: 120, width: 1100, height: 800), operation: .copy, fraction: 1)
NSGraphicsContext.restoreGraphicsState()
let px = mask.bitmapData!
for i in stride(from: 0, to: mw * mh * 4, by: 4) {
    let r = Double(px[i]), g = Double(px[i + 1]), b = Double(px[i + 2])
    let a = max(0, min(255, (b - max(r, g) - 40) * 8))
    (px[i], px[i + 1], px[i + 2], px[i + 3]) = (0, 0, 0, UInt8(a))
}
try! mask.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "MenuMark.png"))
