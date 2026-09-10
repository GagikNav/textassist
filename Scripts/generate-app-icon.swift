import AppKit
import Foundation

let outputDir = "TextSummarizer/Assets.xcassets/AppIcon.appiconset"
let sourcePath = "TextSummarizer/Assets.xcassets/icon-source/convert_to_text_500dp_8B7DBE_FILL0_wght400_GRAD0_opsz48.png"
let sizes = [(16, "16x16"), (32, "32x32"), (128, "128x128"), (256, "256x256"), (512, "512x512")]

func loadSource() -> NSImage {
    guard let image = NSImage(contentsOfFile: sourcePath) else {
        fatalError("Could not load source icon at \(sourcePath)")
    }
    return image
}

func makeBaseIcon(source: NSImage) -> NSImage {
    let s: CGFloat = 1024
    let iconFillRatio: CGFloat = 0.82
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    // Transparent background
    let fullRect = CGRect(origin: .zero, size: CGSize(width: s, height: s))
    NSColor.clear.setFill()
    fullRect.fill()

    // Draw the source icon centered, filling most of the canvas
    let iconSize = s * iconFillRatio
    let iconRect = NSRect(
        x: (s - iconSize) / 2,
        y: (s - iconSize) / 2,
        width: iconSize,
        height: iconSize
    )

    NSGraphicsContext.current?.imageInterpolation = .high
    source.draw(in: iconRect, from: NSRect(origin: .zero, size: source.size), operation: .sourceOver, fraction: 1.0)

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, size: Int, suffix: String) throws {
    // Create a bitmap with exact pixel dimensions at 1x scale
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Could not create bitmap")
    }

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current = context
    NSGraphicsContext.current?.imageInterpolation = .high

    image.draw(in: NSRect(origin: .zero, size: NSSize(width: size, height: size)), from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1.0)

    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("PNG export failed")
    }

    let url = URL(fileURLWithPath: "\(outputDir)/icon_\(suffix).png")
    try data.write(to: url)
    print("Saved \(url.path) (\(size)x\(size))")
}

let source = loadSource()
let base = makeBaseIcon(source: source)
for (size, suffix) in sizes {
    try savePNG(base, size: size, suffix: suffix)
    try savePNG(base, size: size * 2, suffix: "\(suffix)@2x")
}
