import AppKit

/// 覆盖所有屏幕的纯黑遮罩窗口，带极简的退出提示。
/// - 每块屏幕一个无边框窗口，level 为屏幕保护级（1000），盖住一切普通界面；
/// - 监听屏幕参数变化（插拔显示器自动重建）。
final class ShieldWindowController {
    private var windows: [NSWindow] = []
    private var screenObserver: NSObjectProtocol?
    private var isShown = false

    func show() {
        guard !isShown else { return }
        isShown = true
        rebuild()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.rebuild()
        }
    }

    func hide() {
        isShown = false
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
            screenObserver = nil
        }
        for window in windows { window.orderOut(nil) }
        windows.removeAll()
    }

    private func rebuild() {
        for window in windows { window.orderOut(nil) }
        windows.removeAll()

        for screen in NSScreen.screens {
            windows.append(makeWindow(for: screen))
        }
        logInfo("遮罩窗口已覆盖 \(windows.count) 块屏幕")
    }

    private func makeWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .black
        window.level = .screenSaver
        window.isOpaque = true
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.hidesOnDeactivate = false
        window.animationBehavior = .none
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.contentView = ShieldContentView(frame: NSRect(origin: .zero, size: screen.frame.size))
        window.orderFrontRegardless()
        return window
    }
}

/// 黑屏上的居中提示文字（直接绘制，不用 Auto Layout）。
final class ShieldContentView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 19, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.52),
        ]
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.white.withAlphaComponent(0.28),
        ]
        let hintAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.20),
        ]

        let title = L10n.wipeTitle as NSString
        let subtitle = L10n.wipeSubtitle as NSString
        let hint = L10n.wipeExitHint as NSString

        let titleSize = title.size(withAttributes: titleAttrs)
        let subtitleSize = subtitle.size(withAttributes: subtitleAttrs)
        let hintSize = hint.size(withAttributes: hintAttrs)

        let gap1: CGFloat = 9
        let gap2: CGFloat = 26
        let totalHeight = titleSize.height + gap1 + subtitleSize.height + gap2 + hintSize.height
        let top = bounds.midY + totalHeight / 2

        title.draw(at: NSPoint(x: bounds.midX - titleSize.width / 2,
                               y: top - titleSize.height),
                   withAttributes: titleAttrs)
        subtitle.draw(at: NSPoint(x: bounds.midX - subtitleSize.width / 2,
                                  y: top - titleSize.height - gap1 - subtitleSize.height),
                      withAttributes: subtitleAttrs)
        hint.draw(at: NSPoint(x: bounds.midX - hintSize.width / 2,
                              y: top - titleSize.height - gap1 - subtitleSize.height - gap2 - hintSize.height),
                  withAttributes: hintAttrs)
    }
}
