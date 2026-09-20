import AppKit
import ApplicationServices

enum AccessibilityPermission {
    static var isGranted: Bool {
        AXIsProcessTrusted()
    }

    /// 让系统弹出“辅助功能”授权引导（会把本 App 加入列表，用户手动打开开关）。
    static func promptSystemDialog() {
        let key = kAXTrustedCheckOptionPrompt
        let options = [key.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// 直接打开系统设置的辅助功能面板。
    static func openSystemSettings() {
        let urlString: String
        if #available(macOS 13.0, *) {
            urlString = "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
        } else {
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        }
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
