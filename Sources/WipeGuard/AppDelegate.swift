import AppKit
import Carbon.HIToolbox

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindow: NSWindow?
    private var loginCheckbox: NSButton?
    private var session: WipeSession?
    private let hotKeyCenter = HotKeyCenter()
    private var selfTestTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()
        buildMainWindow()

        hotKeyCenter.register(
            keyCode: Int(kVK_ANSI_K),
            modifiers: UInt32(cmdKey | optionKey)
        ) { [weak self] in
            self?.startWipe()
        }

        // 核心体验：双击打开 App 即进入擦拭模式。
        if AppOptions.selfTestAutoStart {
            // 自测复现：模拟用户点击「开始擦拭模式」按钮。
            logInfo("SELFTEST: 自动触发 startWipe（模拟点击开始按钮）")
            startWipe()
        }

        // 自测安全网：加入 .common modes，即使卡在模态对话框里也能按时退出。
        if let seconds = AppOptions.selfTestSeconds {
            logInfo("自测模式：\(seconds) 秒后自动清理并退出")
            let timer = Timer(timeInterval: seconds, repeats: false) { [weak self] _ in
                logInfo("SELFTEST: 超时触发，清理并退出")
                self?.session?.stop()
                exit(0)
            }
            RunLoop.main.add(timer, forMode: .common)
            selfTestTimer = timer
        }
    }

    /// 点击 Dock 图标时重新显示主窗口。
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        mainWindow?.makeKeyAndOrderFront(nil)
        return true
    }

    // MARK: - 擦拭模式

    @objc private func startWipe() {
        guard session == nil else {
            logInfo("SELFTEST: startWipe 重入被拒（session 已存在）")
            return
        }
        guard AccessibilityPermission.isGranted else {
            logInfo("SELFTEST: 无辅助功能权限，弹引导")
            showPermissionGuide()
            return
        }
        logInfo("SELFTEST: 权限正常，创建 WipeSession")
        let newSession = WipeSession { [weak self] in
            self?.session = nil
            self?.showMainWindow()
        }
        // 先占位再启动：AppKit 在触控板手势事件中可能嵌套跑事件循环、重入调用本方法，
        // 若等 start() 成功后才赋值，重入调用会穿过 session==nil 的防线（v1.1.0 崩溃根因）。
        session = newSession
        if !newSession.start() {
            session = nil
            showTapFailureAlert()
        }
    }

    private func showTapFailureAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = L10n.tapFailTitle
        alert.informativeText = L10n.tapFailBody
        alert.addButton(withTitle: L10n.permOpenSettings)
        alert.addButton(withTitle: "OK")
        if alert.runModal() == .alertFirstButtonReturn {
            AccessibilityPermission.openSystemSettings()
        }
    }

    private func showPermissionGuide() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = L10n.permTitle
        alert.informativeText = L10n.permBody
        alert.addButton(withTitle: L10n.permOpenSettings)
        alert.addButton(withTitle: L10n.permRetry)
        alert.addButton(withTitle: L10n.permLater)
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            AccessibilityPermission.promptSystemDialog()
            AccessibilityPermission.openSystemSettings()
        case .alertSecondButtonReturn:
            if AccessibilityPermission.isGranted {
                startWipe()
            } else {
                showPermissionGuide()
            }
        default:
            break // “稍后”：主窗口仍在，随时点按钮或 ⌥⌘K 启动
        }
    }

    // MARK: - 主窗口

    private func buildMainWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 440),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.appName
        window.center()
        window.isReleasedWhenClosed = false // 关闭仅隐藏窗口，App 留在 Dock

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 440))

        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.setFrameSize(NSSize(width: 100, height: 100))

        let title = NSTextField(labelWithString: L10n.appName)
        title.font = .systemFont(ofSize: 22, weight: .bold)

        let subtitle = NSTextField(labelWithString: L10n.mainSubtitle)
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabelColor

        let startButton = NSButton(title: L10n.mainStartButton, target: self, action: #selector(startWipe))
        startButton.bezelStyle = .rounded
        startButton.font = .systemFont(ofSize: 15, weight: .semibold)
        startButton.keyEquivalent = "\r"

        let hint = NSTextField(labelWithString: L10n.mainEscHint)
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = .tertiaryLabelColor

        let checkbox = NSButton(checkboxWithTitle: L10n.menuLoginItem, target: self, action: #selector(toggleLoginItem(_:)))
        checkbox.title = L10n.menuLoginItem
        checkbox.state = LoginItem.isEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
        if !LoginItem.isSupported { checkbox.isHidden = true }

        let stack = NSStackView(views: [icon, title, subtitle, startButton, hint, checkbox])
        stack.orientation = NSUserInterfaceLayoutOrientation.vertical
        stack.alignment = NSLayoutConstraint.Attribute.centerX
        stack.spacing = 14
        stack.setCustomSpacing(20, after: icon)
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor, constant: -8),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -24),
        ])

        window.contentView = content
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        mainWindow = window
        loginCheckbox = checkbox
    }

    private func showMainWindow() {
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - 主菜单

    private func buildMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: L10n.menuAbout,
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: L10n.menuQuit,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        NSApp.mainMenu = mainMenu
    }

    // MARK: - 登录自启

    @objc private func toggleLoginItem(_ sender: NSButton) {
        LoginItem.setEnabled(sender.state == NSControl.StateValue.on)
        sender.state = LoginItem.isEnabled ? NSControl.StateValue.on : NSControl.StateValue.off // 设置失败时回滚显示
    }
}
