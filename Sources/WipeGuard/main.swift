import AppKit

// main.swift 是 Swift 多文件编译中唯一允许顶层执行代码的文件。

let arguments = CommandLine.arguments

if arguments.contains("--version") {
    print("WipeGuard \(AppOptions.version)")
    exit(0)
}

if arguments.contains("--help") {
    print("""
    WipeGuard 擦屏卫士 — 擦拭屏幕 / 键盘时锁定一切输入

    用法:
      双击 WipeGuard.app          直接进入擦拭模式，按 esc 退出
      --self-test <秒>            自动化自测: N 秒后自动清理并退出进程
      --version                   查看版本
    """)
    exit(0)
}

var index = 1
while index < arguments.count {
    if arguments[index] == "--self-test",
       index + 1 < arguments.count,
       let seconds = Double(arguments[index + 1]) {
        AppOptions.selfTestSeconds = seconds
    }
    if arguments[index] == "--self-test-start" {
        AppOptions.selfTestAutoStart = true
    }
    index += 1
}

// 单实例保护：重复打开时激活已有实例后退出。
let myPID = ProcessInfo.processInfo.processIdentifier
let others = NSRunningApplication
    .runningApplications(withBundleIdentifier: AppOptions.bundleID)
    .filter { $0.processIdentifier != myPID }
if let running = others.first {
    logInfo("已有实例在运行 (pid \(running.processIdentifier))，激活它并退出本次启动")
    _ = running.activate()
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
