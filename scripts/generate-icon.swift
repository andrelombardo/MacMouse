// Original vector geometry, rendered with AppKit. No external graphic assets.
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resources = root.appendingPathComponent("Sources/MacMouse/Resources")
let catalog = resources.appendingPathComponent("Assets.xcassets/AppIcon.appiconset")
let iconset = root.appendingPathComponent("build/AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: catalog, withIntermediateDirectories: true)
var images = [[String: String]]()
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let size = points * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let transform = NSAffineTransform()
        transform.scale(by: CGFloat(size) / 1024)
        transform.concat()
        let pale = NSColor(srgbRed: 229/255, green: 232/255, blue: 237/255, alpha: 1)
        let ink = NSColor(srgbRed: 70/255, green: 80/255, blue: 94/255, alpha: 1)
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat, _ color: NSColor) {
            color.setFill()
            NSBezierPath(roundedRect: NSRect(x: x, y: 1024-y-h, width: w, height: h), xRadius: radius, yRadius: radius).fill()
        }
        rect(72, 72, 880, 880, 202, pale)
        rect(328, 178, 368, 668, 184, ink)
        pale.setStroke()
        let seam = NSBezierPath()
        seam.move(to: NSPoint(x: 328, y: 608)); seam.line(to: NSPoint(x: 696, y: 608))
        seam.move(to: NSPoint(x: 512, y: 846)); seam.line(to: NSPoint(x: 512, y: 608))
        seam.lineWidth = 13; seam.stroke()
        rect(492, 268, 40, 96, 20, pale)
        rect(280, 454, 22, 74, 11, ink)
        rect(280, 548, 22, 74, 11, ink)
        NSGraphicsContext.restoreGraphicsState()
        let filename = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        let png = bitmap.representation(using: .png, properties: [:])!
        try png.write(to: iconset.appendingPathComponent(filename))
        try png.write(to: catalog.appendingPathComponent(filename))
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": filename])
    }
}
let contents: [String: Any] = ["images": images, "info": ["version": 1, "author": "MacMouse"]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: catalog.appendingPathComponent("Contents.json"))
try Data("{\"info\":{\"version\":1,\"author\":\"MacMouse\"}}\n".utf8)
    .write(to: resources.appendingPathComponent("Assets.xcassets/Contents.json"))
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", resources.appendingPathComponent("AppIcon.icns").path]
try task.run(); task.waitUntilExit()
guard task.terminationStatus == 0 else { exit(1) }
