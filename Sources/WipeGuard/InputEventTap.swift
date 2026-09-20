import AppKit
import Carbon.HIToolbox
import CoreGraphics

/// 系统级输入拦截器：在登录会话层（CGEventTap）拦截并丢弃所有输入事件。
///
/// 设计：订阅**全部**事件类型（键盘、鼠标、触控板、滚轮、手势、压力、数位板、
/// NX_SYSDEFINED 媒体键，以及未来新增的类型），再按白名单放行：
/// - `esc`：触发 onEscape，事件本身也被消耗；
/// - 电源键（NX_KEY_TYPE_POWER / 键码 130）：放行，保留系统原生行为；
/// - 其余一切：直接丢弃（包括亮度、音量等媒体键和捏合、轻扫等触控板手势）。
final class InputEventTap {
    private var machPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let onEscape: () -> Void
    private let onInvalidated: () -> Void

    init(onEscape: @escaping () -> Void, onInvalidated: @escaping () -> Void) {
        self.onEscape = onEscape
        self.onInvalidated = onInvalidated
    }

    /// 创建并启用事件 tap。返回 false 表示创建失败（几乎总是缺少辅助功能权限）。
    /// 幂等：重复调用不会崩溃（AppKit 在触控板手势事件中可能嵌套跑事件循环、
    /// 重入触发按钮 action，导致本方法被意外调用两次）。
    func install() -> Bool {
        if machPort != nil {
            logError("InputEventTap 重复安装请求（已忽略）")
            return true
        }

        // 全事件类型掩码：任何现有或未来新增的事件类型都进入回调，由白名单决定去留。
        // 注意：必须写 ~CGEventMask(0)（UInt64 自身的按位取反）。若写 CGEventMask(~0)，
        // ~0 会被推断为 Int(-1)，Int → UInt64 的负数转换在运行时触发崩溃陷阱
        // （v1.0.1–v1.1.1「点击开始必闪退」的根因）。
        let mask = ~CGEventMask(0)

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: inputTapCallback,
            userInfo: refcon
        ) else {
            logError("CGEventTap 创建失败（大概率是辅助功能权限未授予）")
            return false
        }
        machPort = port

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0) else {
            CFMachPortInvalidate(port)
            machPort = nil
            logError("CFMachPortCreateRunLoopSource 失败")
            return false
        }
        runLoopSource = source
        CFRunLoopAddSource(RunLoop.main.getCFRunLoop(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        logInfo("输入拦截 tap 已启用")
        return true
    }

    func uninstall() {
        if let source = runLoopSource {
            CFRunLoopSourceInvalidate(source)
            CFRunLoopRemoveSource(RunLoop.main.getCFRunLoop(), source, .commonModes)
            runLoopSource = nil
        }
        if let port = machPort {
            CGEvent.tapEnable(tap: port, enable: false)
            CFMachPortInvalidate(port)
            machPort = nil
            logInfo("输入拦截 tap 已停用")
        }
    }

    deinit { uninstall() }
}

/// CGEventTapCallBack 必须是纯 C 函数指针，通过 refcon 找回对象。
private func inputTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passRetained(event) }
    let controller = Unmanaged<InputEventTap>.fromOpaque(refcon).takeUnretainedValue()
    return controller.handle(type: type, event: event)
}

extension InputEventTap {
    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout:
            // 回调偶发超时被系统禁用：立即重新启用。
            if let port = machPort { CGEvent.tapEnable(tap: port, enable: true) }
            return Unmanaged.passRetained(event)

        case .tapDisabledByUserInput:
            // 无法恢复的失效：立刻通知上层结束擦拭模式，绝不停留在“假锁定”状态。
            DispatchQueue.main.async { [weak self] in self?.onInvalidated() }
            return Unmanaged.passRetained(event)

        case _ where type.rawValue == 14: // NX_SYSDEFINED
            return Self.filterSystemDefined(event)

        case .keyDown, .keyUp:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            if type == .keyDown && keyCode == Int64(kVK_Escape) {
                // 异步触发：不能在 tap 回调内同步拆卸 tap 自身。
                DispatchQueue.main.async { [weak self] in self?.onEscape() }
                return nil
            }
            if keyCode == 130 {
                // 电源键（部分外接键盘以普通键码 130 上报）：按下与抬起都放行。
                return Unmanaged.passRetained(event)
            }
            return nil

        default:
            // 修饰键、鼠标、触控板、滚轮、手势、压力、数位板等：全部丢弃。
            return nil
        }
    }

    /// NX_SYSDEFINED 系统事件白名单：只放行电源键（NX_KEY_TYPE_POWER）。
    ///
    /// 亮度、音量、静音、键盘背光、播放控制、推出等媒体键不走普通键盘事件，
    /// 而是以 subtype 8（auxControlButtons）的系统事件抵达，媒体键码在 data1 的高 16 位。
    /// 若整个通道放行，擦拭时碰到的 F1/F2/F10–F12 仍会调亮度、改音量。
    private static func filterSystemDefined(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        guard let nsEvent = NSEvent(cgEvent: event) else { return nil }
        guard nsEvent.subtype.rawValue == 8 else { return nil }
        let keyCode = (nsEvent.data1 & 0xFFFF0000) >> 16
        if keyCode == 6 { // NX_KEY_TYPE_POWER
            return Unmanaged.passRetained(event)
        }
        return nil
    }
}
