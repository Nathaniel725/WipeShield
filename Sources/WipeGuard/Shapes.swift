import AppKit

/// 共享矢量形状：盾牌与四角星（擦亮火花）。菜单栏图标直接用这两个形状绘制。
enum ShieldShape {
    static func path(in rect: NSRect) -> NSBezierPath {
        let p = NSBezierPath()
        let x = rect.minX, y = rect.minY
        let w = rect.width, h = rect.height
        p.move(to: NSPoint(x: x + 0.50 * w, y: y))                                  // 底尖
        p.curve(to: NSPoint(x: x, y: y + 0.58 * h),                                  // 左下弧
                controlPoint1: NSPoint(x: x + 0.17 * w, y: y + 0.30 * h),
                controlPoint2: NSPoint(x: x, y: y + 0.44 * h))
        p.line(to: NSPoint(x: x, y: y + 0.90 * h))                                   // 左直边
        p.curve(to: NSPoint(x: x + 0.07 * w, y: y + h),                              // 左上圆角
                controlPoint1: NSPoint(x: x, y: y + 0.97 * h),
                controlPoint2: NSPoint(x: x + 0.02 * w, y: y + h))
        p.line(to: NSPoint(x: x + 0.93 * w, y: y + h))                               // 顶边
        p.curve(to: NSPoint(x: x + w, y: y + 0.90 * h),                              // 右上圆角
                controlPoint1: NSPoint(x: x + 0.98 * w, y: y + h),
                controlPoint2: NSPoint(x: x + w, y: y + 0.97 * h))
        p.line(to: NSPoint(x: x + w, y: y + 0.58 * h))                               // 右直边
        p.curve(to: NSPoint(x: x + 0.50 * w, y: y),                                  // 右下弧
                controlPoint1: NSPoint(x: x + w, y: y + 0.44 * h),
                controlPoint2: NSPoint(x: x + 0.83 * w, y: y + 0.30 * h))
        p.close()
        return p
    }
}

enum SparkleShape {
    /// 四角星（凹边），中心的“擦净”意象。
    static func path(center: NSPoint, outer: CGFloat, inner: CGFloat) -> NSBezierPath {
        let p = NSBezierPath()
        let c = center
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
}

/// 菜单栏小图标（template 图像，自动适配深/浅色菜单栏）。
enum MenuBarIcon {
    static func make() -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 20))
        image.lockFocus()
        let shield = ShieldShape.path(in: NSRect(x: 3.2, y: 3.2, width: 13.6, height: 13.6))
        shield.lineWidth = 1.5
        NSColor.controlTextColor.setStroke()
        shield.stroke()
        let sparkle = SparkleShape.path(center: NSPoint(x: 10, y: 10.2), outer: 3.8, inner: 1.05)
        NSColor.controlTextColor.setFill()
        sparkle.fill()
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
