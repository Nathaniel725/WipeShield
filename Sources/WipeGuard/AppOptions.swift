import Foundation
import os

enum AppOptions {
    static let version = "1.2.0"
    static let bundleID = Bundle.main.bundleIdentifier ?? "com.wipeguard.mac"

    /// 自测模式：N 秒后自动结束擦拭模式并退出进程（自动化测试的安全网）。
    static var selfTestSeconds: Double?
    /// 自测模式：启动后自动调用一次 startWipe（复现"点击开始"路径）。
    static var selfTestAutoStart = false
}

private let osLog = OSLog(subsystem: AppOptions.bundleID, category: "app")

func logInfo(_ message: String) {
    os_log("%{public}s", log: osLog, type: .info, message)
    if AppOptions.selfTestSeconds != nil {
        print("[WipeGuard] \(message)")
    }
}

func logError(_ message: String) {
    os_log("%{public}s", log: osLog, type: .error, message)
    if AppOptions.selfTestSeconds != nil {
        FileHandle.standardError.write(Data("[WipeGuard][ERROR] \(message)\n".utf8))
    }
}
