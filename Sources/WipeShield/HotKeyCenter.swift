import AppKit
import Carbon.HIToolbox

/// 全局热键（⌥⌘K）：随时进入擦拭模式。
/// Carbon RegisterEventHotKey 无需任何权限，且与 NSApplication 事件循环兼容。
final class HotKeyCenter {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var box: HotKeyBox?

    func register(keyCode: Int, modifiers: UInt32, handler: @escaping () -> Void) {
        unregister()

        let box = HotKeyBox(handler: handler)
        self.box = box

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = Unmanaged.passRetained(box).toOpaque()
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }
                var hotKeyID = EventHotKeyID()
                let err = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                if err == noErr, hotKeyID.id == 1 {
                    let box = Unmanaged<HotKeyBox>.fromOpaque(userData).takeUnretainedValue()
                    DispatchQueue.main.async { box.handler() }
                }
                return noErr
            },
            1, &spec, userData, &handlerRef
        )
        guard installStatus == noErr else {
            logError("InstallEventHandler 失败 (\(installStatus))，全局热键不可用")
            releaseBox()
            return
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x57504744) /* 'WPGD' */, id: 1)
        let registerStatus = RegisterEventHotKey(
            UInt32(keyCode), modifiers, hotKeyID,
            GetApplicationEventTarget(), 0, &hotKeyRef
        )
        if registerStatus == noErr {
            logInfo("全局热键 ⌥⌘K 已注册")
        } else {
            logError("RegisterEventHotKey 失败 (\(registerStatus))，全局热键不可用")
            releaseBox()
        }
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = handlerRef {
            RemoveEventHandler(ref)
            handlerRef = nil
        }
        releaseBox()
    }

    private func releaseBox() {
        if let box = box {
            Unmanaged.passUnretained(box).release()
            self.box = nil
        }
    }

    deinit { unregister() }
}

private final class HotKeyBox {
    let handler: () -> Void
    init(handler: @escaping () -> Void) { self.handler = handler }
}
