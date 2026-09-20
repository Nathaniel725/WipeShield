import Foundation

/// 标准本地化：界面语言跟随系统设置（可在 系统设置 → 通用 → 语言与地区 里为单个 App 指定）。
/// 添加新语言 = 在 resources/Localizations/ 下新建 <lang>.lproj/Localizable.strings，
/// 并在 Info.plist 的 CFBundleLocalizations 里登记，无需改动任何代码。
enum L10n {
    private static func tr(_ key: String) -> String {
        NSLocalizedString(key, bundle: .main, comment: "")
    }

    static var appName: String { tr("app.name") }

    // 遮罩屏上的提示
    static var wipeTitle: String { tr("wipe.title") }
    static var wipeSubtitle: String { tr("wipe.subtitle") }
    static var wipeExitHint: String { tr("wipe.exit") }

    // 主窗口
    static var mainSubtitle: String { tr("main.subtitle") }
    static var mainStartButton: String { tr("main.start") }
    static var mainEscHint: String { tr("main.hint") }

    // 菜单
    static var menuLoginItem: String { tr("menu.login") }
    static var menuAbout: String { tr("menu.about") }
    static var menuQuit: String { tr("menu.quit") }

    // 权限引导
    static var permTitle: String { tr("perm.title") }
    static var permBody: String { tr("perm.body") }
    static var permOpenSettings: String { tr("perm.open") }
    static var permRetry: String { tr("perm.retry") }
    static var permLater: String { tr("perm.later") }

    // 事件拦截启动失败
    static var tapFailTitle: String { tr("tapfail.title") }
    static var tapFailBody: String { tr("tapfail.body") }
}
