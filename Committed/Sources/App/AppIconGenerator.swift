import AppKit
import SwiftUI

enum AppIconGenerator {
    static func generateIcon() -> NSImage {
        let size = NSSize(width: 1024, height: 1024)
        let image = NSImage(size: size)

        image.lockFocus()

        // Background: dark rounded rect
        let bgPath = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 220, yRadius: 220)
        NSColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0).setFill()
        bgPath.fill()

        // Draw the SF Symbol
        let config = NSImage.SymbolConfiguration(pointSize: 500, weight: .bold)
        if let symbol = NSImage(systemSymbolName: "checkmark.seal.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(config) {
            let symbolSize = symbol.size
            let x = (size.width - symbolSize.width) / 2
            let y = (size.height - symbolSize.height) / 2
            symbol.draw(in: NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height),
                       from: .zero, operation: .sourceOver, fraction: 1.0)
        }

        image.unlockFocus()
        return image
    }

    static func saveIconSet(to directory: String) {
        let sizes: [(Int, String)] = [
            (16, "16x16"),
            (32, "16x16@2x"),
            (32, "32x32"),
            (64, "32x32@2x"),
            (128, "128x128"),
            (256, "128x128@2x"),
            (256, "256x256"),
            (512, "256x256@2x"),
            (512, "512x512"),
            (1024, "512x512@2x")
        ]

        let iconsetDir = (directory as NSString).appendingPathComponent("AppIcon.iconset")
        try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

        let baseImage = generateIcon()

        for (size, name) in sizes {
            let resized = NSImage(size: NSSize(width: size, height: size))
            resized.lockFocus()
            baseImage.draw(in: NSRect(x: 0, y: 0, width: size, height: size),
                          from: .zero, operation: .sourceOver, fraction: 1.0)
            resized.unlockFocus()

            if let tiff = resized.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                let filePath = (iconsetDir as NSString).appendingPathComponent("icon_\(name).png")
                try? png.write(to: URL(fileURLWithPath: filePath))
            }
        }
    }
}
