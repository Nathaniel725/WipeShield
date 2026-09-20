import Foundation

/// 轻量双语（跟随系统语言）。界面文案很少，无需完整 Localizable 体系。
enum L10n {
    static let prefersChinese: Bool = {
        Locale.preferredLanguages.first?.hasPrefix("zh") == true
    }()

    static var appName: String { prefersChinese ? "擦屏卫士" : "WipeGuard" }

    // 遮罩屏上的提示
    static var wipeTitle: String { prefersChinese ? "擦拭模式" : "Cleaning Mode" }
    static var wipeSubtitle: String {
        prefersChinese ? "键盘 · 触控板 · 鼠标输入已全部拦截" : "Keyboard · trackpad · mouse input is blocked"
    }
    static var wipeExitHint: String { prefersChinese ? "按 esc 退出" : "Press esc to exit" }

    // 主窗口
    static var mainSubtitle: String {
        prefersChinese ? "擦拭屏幕与键盘时，锁定一切输入" : "Lock all input while you clean"
    }
    static var mainStartButton: String { prefersChinese ? "开始擦拭模式" : "Start Cleaning Mode" }
    static var mainEscHint: String {
        prefersChinese ? "擦拭中按 esc 退出 · 随时可用 ⌥⌘K 开始" : "esc to finish · ⌥⌘K to start anytime"
    }

    // 菜单
    static var menuLoginItem: String { prefersChinese ? "登录时自动启动" : "Launch at Login" }
    static var menuAbout: String { prefersChinese ? "关于 \(appName)" : "About \(appName)" }
    static var menuQuit: String { prefersChinese ? "退出 \(appName)" : "Quit \(appName)" }

    // 权限引导
    static var permTitle: String {
        prefersChinese ? "「\(appName)」需要辅助功能权限" : "\(appName) Needs Accessibility Permission"
    }
    static var permBody: String {
        prefersChinese
            ? "拦截键盘和鼠标输入，需要授予「辅助功能」权限。\n\n请前往 系统设置 → 隐私与安全性 → 辅助功能，允许「\(appName)」。"
            : "Blocking keyboard & mouse input requires the Accessibility permission.\n\nSystem Settings → Privacy & Security → Accessibility → allow \(appName)."
    }
    static var permOpenSettings: String { prefersChinese ? "打开系统设置" : "Open System Settings" }
    static var permRetry: String { prefersChinese ? "我已授权，重试" : "Granted, Retry" }
    static var permLater: String { prefersChinese ? "稍后" : "Later" }

    // 事件拦截启动失败
    static var tapFailTitle: String { prefersChinese ? "无法启动擦拭模式" : "Cannot Start Cleaning Mode" }
    static var tapFailBody: String {
        prefersChinese
            ? "输入拦截初始化失败（通常是辅助功能权限未授予或被撤销）。为避免「假锁定」，本次未进入擦拭模式。"
            : "Failed to install the input blocker (usually the Accessibility permission is missing). Cleaning mode was NOT started to avoid a false sense of safety."
    }
}
