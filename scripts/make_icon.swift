import AppKit

// 生成 WipeShield 应用图标（iconset → iconutil 转 icns）。
// 用法: swift scripts/make_icon.swift <输出 iconset 路径>

let args = CommandLine.arguments
let outPath = args.count > 1 ? args[1] : "WipeShield.iconset"
try! FileManager.default.createDirectory(atPath: outPath, withIntermediateDirectories: true)

let entries: [(String, CGFloat)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]

for (name, px) in entries {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(px), pixelsHigh: Int(px),
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ) else { fatalError("无法创建位图 \(name)") }
    rep.size = NSSize(width: px, height: px)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    drawIcon(size: px)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("PNG 编码失败 \(name)")
    }
    let url = URL(fileURLWithPath: outPath).appendingPathComponent(name)
    try! data.write(to: url)
    print("wrote \(url.path)")
}

// MARK: - 绘制

func drawIcon(size s: CGFloat) {
    // 背景：深石墨渐变的圆角方形
    let inset = s * 0.04
    let radius = s * 0.2225
    let bgRect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let background = NSBezierPath(roundedRect: bgRect, xRadius: radius, yRadius: radius)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.20, green: 0.205, blue: 0.225, alpha: 1),
        NSColor(calibratedRed: 0.095, green: 0.095, blue: 0.11, alpha: 1),
    ])!.draw(in: bgRect, angle: -90)

    background.lineWidth = max(1, s * 0.008)
    NSColor(white: 1, alpha: 0.10).setStroke()
    background.stroke()

    // 盾牌：银白渐变
    let shieldW = s * 0.50
    let shieldH = s * 0.565
    let shieldRect = NSRect(
        x: (s - shieldW) / 2,
        y: (s - shieldH) / 2 - s * 0.012,
        width: shieldW, height: shieldH
    )
    let shield = shieldPath(in: shieldRect)
    NSGradient(colors: [
        NSColor(calibratedWhite: 0.98, alpha: 1),
        NSColor(calibratedWhite: 0.84, alpha: 1),
    ])!.draw(in: shield, angle: -90)

    // 盾内：深色四角星（“擦净”）+ 两个小星点
    let center = NSPoint(x: shieldRect.midX, y: shieldRect.midY + shieldH * 0.04)
    let sparkle = sparklePath(center: center, outer: shieldW * 0.30, inner: shieldW * 0.088)
    NSColor(calibratedRed: 0.13, green: 0.135, blue: 0.155, alpha: 1).setFill()
    sparkle.fill()

    let dot1Size = shieldW * 0.055
    let dot1 = NSBezierPath(ovalIn: NSRect(
        x: center.x + shieldW * 0.26, y: center.y + shieldH * 0.22,
        width: dot1Size, height: dot1Size
    ))
    NSColor(calibratedWhite: 0.13, alpha: 0.55).setFill()
    dot1.fill()

    let dot2Size = shieldW * 0.04
    let dot2 = NSBezierPath(ovalIn: NSRect(
        x: center.x - shieldW * 0.32, y: center.y - shieldH * 0.20,
        width: dot2Size, height: dot2Size
    ))
    NSColor(calibratedWhite: 0.13, alpha: 0.45).setFill()
    dot2.fill()
}

func shieldPath(in rect: NSRect) -> NSBezierPath {
    let p = NSBezierPath()
    let x = rect.minX, y = rect.minY
    let w = rect.width, h = rect.height
    p.move(to: NSPoint(x: x + 0.50 * w, y: y))
    p.curve(to: NSPoint(x: x, y: y + 0.58 * h),
            controlPoint1: NSPoint(x: x + 0.17 * w, y: y + 0.30 * h),
            controlPoint2: NSPoint(x: x, y: y + 0.44 * h))
    p.line(to: NSPoint(x: x, y: y + 0.90 * h))
    p.curve(to: NSPoint(x: x + 0.07 * w, y: y + h),
            controlPoint1: NSPoint(x: x, y: y + 0.97 * h),
            controlPoint2: NSPoint(x: x + 0.02 * w, y: y + h))
    p.line(to: NSPoint(x: x + 0.93 * w, y: y + h))
    p.curve(to: NSPoint(x: x + w, y: y + 0.90 * h),
            controlPoint1: NSPoint(x: x + 0.98 * w, y: y + h),
            controlPoint2: NSPoint(x: x + w, y: y + 0.97 * h))
    p.line(to: NSPoint(x: x + w, y: y + 0.58 * h))
    p.curve(to: NSPoint(x: x + 0.50 * w, y: y),
            controlPoint1: NSPoint(x: x + w, y: y + 0.44 * h),
            controlPoint2: NSPoint(x: x + 0.83 * w, y: y + 0.30 * h))
    p.close()
    return p
}

func sparklePath(center c: NSPoint, outer: CGFloat, inner: CGFloat) -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: c.x, y: c.y + outer))
    p.curve(to: NSPoint(x: c.x + outer, y: c.y),
            controlPoint1: NSPoint(x: c.x + inner, y: c.y + inner),
            controlPoint2: NSPoint(x: c.x + inner, y: c.y + inner))
    p.curve(to: NSPoint(x: c.x, y: c.y - outer),
            controlPoint1: NSPoint(x: c.x + inner, y: c.y - inner),
            controlPoint2: NSPoint(x: c.x + inner, y: c.y - inner))
    p.curve(to: NSPoint(x: c.x - outer, y: c.y),
            controlPoint1: NSPoint(x: c.x - inner, y: c.y - inner),
            controlPoint2: NSPoint(x: c.x - inner, y: c.y - inner))
    p.curve(to: NSPoint(x: c.x, y: c.y + outer),
            controlPoint1: NSPoint(x: c.x - inner, y: c.y + inner),
            controlPoint2: NSPoint(x: c.x - inner, y: c.y + inner))
    p.close()
    return p
}
