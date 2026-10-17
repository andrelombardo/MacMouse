#!/usr/bin/env swift
import AppKit

// A plain Finder installation window. Generated at packaging time, not in the app.
let size = NSSize(width: 560, height: 320)
let image = NSImage(size: size)
image.lockFocus()
NSColor(white: 0.96, alpha: 1).setFill()
NSRect(origin: .zero, size: size).fill()
let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 254, y: 190))
arrow.line(to: NSPoint(x: 306, y: 190))
arrow.move(to: NSPoint(x: 295, y: 201))
arrow.line(to: NSPoint(x: 306, y: 190))
arrow.line(to: NSPoint(x: 295, y: 179))
arrow.lineWidth = 2
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
NSColor(white: 0.5, alpha: 1).setStroke()
arrow.stroke()
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
("Trascina MacMouse in Applicazioni" as NSString).draw(
    in: NSRect(x: 20, y: 50, width: 520, height: 24),
    withAttributes: [.font: NSFont.systemFont(ofSize: 15),
                     .foregroundColor: NSColor(white: 0.3, alpha: 1), .paragraphStyle: paragraph])
image.unlockFocus()
guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Sfondo DMG non generato") }
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
