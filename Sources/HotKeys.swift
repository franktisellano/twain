import Carbon.HIToolbox

/// Thin wrapper over Carbon hot keys. They are delivered by the window server
/// straight to our run loop, need no permissions, and swallow the keystroke.
final class HotKeys {
    static let shared = HotKeys()

    private var handlers: [UInt32: () -> Void] = [:]
    private var refs: [UInt32: EventHotKeyRef] = [:]
    private var nextID: UInt32 = 1

    private init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, _ in
            var hk = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hk)
            HotKeys.shared.handlers[hk.id]?()
            return noErr
        }, 1, &spec, nil, nil)
    }

    @discardableResult
    func register(key: Int, modifiers: Int, _ handler: @escaping () -> Void) -> UInt32? {
        let id = nextID
        nextID += 1
        var ref: EventHotKeyRef?
        let hkID = EventHotKeyID(signature: 0x4654_5659 /* 'FTVY' */, id: id)
        let status = RegisterEventHotKey(UInt32(key), UInt32(modifiers), hkID,
                                         GetEventDispatcherTarget(), 0, &ref)
        guard status == noErr, let ref else { return nil }
        refs[id] = ref
        handlers[id] = handler
        return id
    }

    func unregister(_ id: UInt32) {
        if let ref = refs.removeValue(forKey: id) { UnregisterEventHotKey(ref) }
        handlers[id] = nil
    }
}
