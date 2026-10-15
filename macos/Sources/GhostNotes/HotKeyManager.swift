import Cocoa
import Carbon

final class HotKeyManager {
    static let shared = HotKeyManager()
    
    private var hotKeyRefs: [EventHotKeyRef?] = []
    var onTogglePlayPause: (() -> Void)?
    var onToggleGhostMode: (() -> Void)?
    var onScrollUp: (() -> Void)?
    var onScrollDown: (() -> Void)?
    
    private let hotKeyPlayPauseID = EventHotKeyID(signature: OSType(0x47485050), id: 1) // 'GHPP'
    private let hotKeyGhostModeID = EventHotKeyID(signature: OSType(0x4748474D), id: 2) // 'GHGM'
    private let hotKeyScrollUpID = EventHotKeyID(signature: OSType(0x47485355), id: 3) // 'GHSU'
    private let hotKeyScrollDownID = EventHotKeyID(signature: OSType(0x47485344), id: 4) // 'GHSD'

    private init() {
        installEventHandler()
    }
    
    func registerHotKeys() {
        let optionModifier = UInt32(optionKey)
        
        // P = 35 (0x23), L = 37 (0x25), UpArrow = 126 (0x7E), DownArrow = 125 (0x7D)
        registerSingleHotKey(keyCode: UInt32(kVK_ANSI_P), modifier: optionModifier, hotKeyID: hotKeyPlayPauseID)
        registerSingleHotKey(keyCode: UInt32(kVK_ANSI_L), modifier: optionModifier, hotKeyID: hotKeyGhostModeID)
        registerSingleHotKey(keyCode: UInt32(kVK_UpArrow), modifier: optionModifier, hotKeyID: hotKeyScrollUpID)
        registerSingleHotKey(keyCode: UInt32(kVK_DownArrow), modifier: optionModifier, hotKeyID: hotKeyScrollDownID)
    }
    
    private func registerSingleHotKey(keyCode: UInt32, modifier: UInt32, hotKeyID: EventHotKeyID) {
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifier,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr {
            hotKeyRefs.append(ref)
        }
    }
    
    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                guard status == noErr else { return status }
                
                DispatchQueue.main.async {
                    switch hotKeyID.id {
                    case 1:
                        HotKeyManager.shared.onTogglePlayPause?()
                    case 2:
                        HotKeyManager.shared.onToggleGhostMode?()
                    case 3:
                        HotKeyManager.shared.onScrollUp?()
                    case 4:
                        HotKeyManager.shared.onScrollDown?()
                    default:
                        break
                    }
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
    }
    
    deinit {
        for ref in hotKeyRefs {
            if let ref = ref {
                UnregisterEventHotKey(ref)
            }
        }
    }
}
