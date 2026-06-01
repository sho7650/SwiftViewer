#!/usr/bin/env bash
#
# generate-appicon.sh — Generate the macOS AppIcon image set for SwiftViewer.
#
# By default this renders a vector placeholder icon (blue→purple squircle with a
# simple "photo" motif) at every size the asset catalog requires. Pass a path to
# a 1024×1024 master PNG to produce the final icons from real artwork instead:
#
#   ./scripts/generate-appicon.sh                     # placeholder
#   ./scripts/generate-appicon.sh path/to/master.png  # from artwork
#
# Output is written directly into SwiftViewer/Assets.xcassets/AppIcon.appiconset.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONSET_DIR="${SCRIPT_DIR}/../SwiftViewer/Assets.xcassets/AppIcon.appiconset"

if [[ ! -d "$ICONSET_DIR" ]]; then
  echo "error: appiconset not found at $ICONSET_DIR" >&2
  exit 1
fi

SWIFT_FILE="$(mktemp /tmp/gen-appicon.XXXXXX.swift)"
trap 'rm -f "$SWIFT_FILE"' EXIT

cat > "$SWIFT_FILE" <<'SWIFT'
import Foundation
import CoreGraphics
import ImageIO

let env = ProcessInfo.processInfo.environment
let outDir = env["ICONSET_DIR"]!
let masterPath = env["ICON_MASTER"].flatMap { $0.isEmpty ? nil : $0 }
let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

// filename -> pixel dimension
let targets: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

func color(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: srgb, components: [CGFloat(r), CGFloat(g), CGFloat(b), CGFloat(a)])!
}

func loadMaster() -> CGImage? {
    guard let path = masterPath else { return nil }
    let url = URL(fileURLWithPath: path)
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
        FileHandle.standardError.write("warning: could not read master \(path); using placeholder\n".data(using: .utf8)!)
        return nil
    }
    return img
}

func makeContext(_ size: Int) -> CGContext {
    CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
              bytesPerRow: 0, space: srgb,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func drawPlaceholder(_ ctx: CGContext, _ s: CGFloat) {
    // Transparent margin around a rounded-square (squircle-ish) background.
    let m = s * 0.06
    let side = s - 2 * m
    let bg = CGRect(x: m, y: m, width: side, height: side)
    let r = side * 0.22

    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: bg, cornerWidth: r, cornerHeight: r, transform: nil))
    ctx.clip()
    let grad = CGGradient(colorsSpace: srgb,
                          colors: [color(0.31, 0.55, 0.97), color(0.42, 0.31, 0.88)] as CFArray,
                          locations: [0, 1])!
    ctx.drawLinearGradient(grad,
                           start: CGPoint(x: bg.midX, y: bg.maxY),
                           end: CGPoint(x: bg.midX, y: bg.minY),
                           options: [])
    ctx.restoreGState()

    // White "photo" card centered inside the background.
    let cardInset = side * 0.24
    let card = bg.insetBy(dx: cardInset, dy: cardInset)
    let cardR = card.width * 0.10
    let cardPath = CGPath(roundedRect: card, cornerWidth: cardR, cornerHeight: cardR, transform: nil)

    ctx.saveGState()
    ctx.addPath(cardPath)
    ctx.setFillColor(color(0.97, 0.98, 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // Clip artwork to the card.
    ctx.saveGState()
    ctx.addPath(cardPath)
    ctx.clip()

    let cw = card.width, ch = card.height
    // Sun
    let sunR = cw * 0.13
    let sunC = CGPoint(x: card.minX + cw * 0.30, y: card.minY + ch * 0.70)
    ctx.setFillColor(color(1.0, 0.76, 0.29))
    ctx.fillEllipse(in: CGRect(x: sunC.x - sunR, y: sunC.y - sunR, width: 2 * sunR, height: 2 * sunR))
    // Back mountain
    ctx.setFillColor(color(0.23, 0.62, 0.62))
    ctx.beginPath()
    ctx.move(to: CGPoint(x: card.minX, y: card.minY))
    ctx.addLine(to: CGPoint(x: card.minX + cw * 0.50, y: card.minY + ch * 0.55))
    ctx.addLine(to: CGPoint(x: card.minX + cw * 0.88, y: card.minY))
    ctx.closePath()
    ctx.fillPath()
    // Front mountain
    ctx.setFillColor(color(0.16, 0.45, 0.52))
    ctx.beginPath()
    ctx.move(to: CGPoint(x: card.minX + cw * 0.34, y: card.minY))
    ctx.addLine(to: CGPoint(x: card.minX + cw * 0.68, y: card.minY + ch * 0.42))
    ctx.addLine(to: CGPoint(x: card.maxX, y: card.minY))
    ctx.closePath()
    ctx.fillPath()

    ctx.restoreGState()
}

func render(size: Int, master: CGImage?) -> CGImage {
    let ctx = makeContext(size)
    let s = CGFloat(size)
    if let master = master {
        ctx.interpolationQuality = .high
        ctx.draw(master, in: CGRect(x: 0, y: 0, width: s, height: s))
    } else {
        drawPlaceholder(ctx, s)
    }
    return ctx.makeImage()!
}

func write(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        fatalError("could not create destination for \(path)")
    }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) {
        fatalError("could not write \(path)")
    }
}

let master = loadMaster()
for (name, px) in targets {
    let image = render(size: px, master: master)
    write(image, to: "\(outDir)/\(name)")
    print("  \(name)  (\(px)x\(px))")
}
SWIFT

export ICONSET_DIR
export ICON_MASTER="${1:-}"

echo "Generating AppIcon set${ICON_MASTER:+ from master: $ICON_MASTER}..."
swift "$SWIFT_FILE"
echo "Done → $ICONSET_DIR"
