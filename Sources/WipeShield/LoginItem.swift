import AppKit
import ServiceManagement

/// 登录时自动启动（macOS 13+ 用 SMAppService；更老的系统隐藏该菜单项）。
enum LoginItem {
    static var isSupported: Bool {
        if #available(macOS 13.0, *) { return true }
        return false
    }

    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    static func setEnabled(_ on: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if on {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                logError("登录项设置失败: \(error.localizedDescription)")
            }
        }
    }
}
