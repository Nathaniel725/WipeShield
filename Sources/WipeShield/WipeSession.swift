import AppKit
import IOKit.pwr_mgt

/// 一次擦拭会话 = 输入拦截 + 全屏遮罩 + 防休眠断言 + 隐藏光标。
///
/// 设计原则：任何一环失败都完整回滚，绝不进入“假锁定”状态
/// （黑屏看似锁定、实际输入照样进系统，比不锁更危险）。
final class WipeSession {
    private let shield = ShieldWindowController()
    private var eventTap: InputEventTap?
    private var powerAssertionID = IOPMAssertionID(0)
    private var powerAssertionHeld = false
    private var sleepObserver: NSObjectProtocol?
    private let onEnd: () -> Void
    private var ended = false

    init(onEnd: @escaping () -> Void) {
        self.onEnd = onEnd
    }

    /// 返回 false = 启动失败（不会留下任何半启动状态）。幂等：重复调用直接按成功返回。
    func start() -> Bool {
        if eventTap != nil {
            logError("WipeSession.start 重复调用（已忽略）")
            return true
        }
        // 1. 事件拦截必须最先就位——先拦截，再遮黑，顺序不能反。
        let tap = InputEventTap(
            onEscape: { [weak self] in self?.stop() },
            onInvalidated: { [weak self] in self?.stop() }
        )
        guard tap.install() else {
            return false
        }
        eventTap = tap

        // 2. 阻止屏幕休眠 / 屏保 / 自动锁屏：擦拭期间系统必须保持现状。
        var assertionID = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            UInt32(kIOPMAssertionLevelOn),
            "WipeShield cleaning in progress" as CFString,
            &assertionID
        )
        if result == kIOReturnSuccess {
            powerAssertionID = assertionID
            powerAssertionHeld = true
            logInfo("已阻止屏幕休眠与屏保")
        } else {
            logError("防休眠断言创建失败 (kIOReturn \(result))，擦拭期间屏幕可能自动休眠")
        }

        // 3. 遮罩盖住所有屏幕，并隐藏光标。
        NSApp.activate(ignoringOtherApps: true)
        shield.show()
        NSCursor.hide()

        // 4. 安全兜底：合盖 / 系统休眠时自动结束擦拭（唤醒后陷入黑屏锁定非常危险）。
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            logInfo("系统即将休眠，自动结束擦拭模式")
            self?.stop()
        }

        logInfo("擦拭模式已启动")
        return true
    }

    func stop() {
        guard !ended else { return }
        ended = true

        if let observer = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            sleepObserver = nil
        }
        NSCursor.unhide()
        shield.hide()
        if powerAssertionHeld {
            IOPMAssertionRelease(powerAssertionID)
            powerAssertionHeld = false
        }
        eventTap?.uninstall()
        eventTap = nil
        logInfo("擦拭模式已结束")
        onEnd()
    }

    deinit { stop() }
}
