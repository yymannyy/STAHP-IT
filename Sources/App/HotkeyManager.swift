import AppKit
import Carbon

@MainActor
public final class HotkeyManager {
    public static let shared = HotkeyManager()
    
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var eventHandler: EventHandlerRef?
    private var localMonitor: Any?
    
    public init() {}
    
    public func setup(appState: AppState) {
        unregisterHotKeys()
        
        // 1. Install Carbon Event Handler for Global System-Wide Shortcuts
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    theEvent,
                    OSType(kEventParamDirectObject),
                    OSType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                if status == noErr {
                    DispatchQueue.main.async {
                        AppState.shared.handleGlobalHotKey(id: hotKeyID.id)
                    }
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )
        
        if handlerStatus == noErr {
            // Carbon Modifiers: optionKey (0x0800 = 2048), shiftKey (0x0200 = 512)
            let optionShift = UInt32(optionKey | shiftKey)
            
            // ID 1: Option + Shift + N (kVK_ANSI_N = 45) -> Toggle Notch / Overlay
            registerHotKey(keyCode: 45, modifiers: optionShift, id: 1)
            
            // ID 2: Option + Shift + O (kVK_ANSI_O = 31) -> Toggle Overlay (Alias)
            registerHotKey(keyCode: 31, modifiers: optionShift, id: 2)
            
            // ID 3: Option + Shift + Space (kVK_Space = 49) -> Start / Pause Timer
            registerHotKey(keyCode: 49, modifiers: optionShift, id: 3)
            
            // ID 4: Option + Shift + S (kVK_ANSI_S = 1) -> Save / Stop Session
            registerHotKey(keyCode: 1, modifiers: optionShift, id: 4)
        }
        
        // 2. Also keep Local Event Monitor when app has focus
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let isOptionShift = flags.contains([.option, .shift])
            
            if flags == .command && (event.charactersIgnoringModifiers == "," || event.keyCode == 43) {
                appState.openSettings()
                return nil
            }
            
            if isOptionShift {
                let char = event.charactersIgnoringModifiers?.lowercased()
                if event.keyCode == 45 || char == "n" {
                    appState.toggleOverlay()
                    return nil
                }
                if event.keyCode == 31 || char == "o" {
                    appState.toggleOverlay()
                    return nil
                }
                if event.keyCode == 49 || char == " " {
                    appState.toggleTimer()
                    return nil
                }
                if event.keyCode == 1 || char == "s" {
                    appState.stopAndSaveSession()
                    return nil
                }
            }
            return event
        }
    }
    
    private func registerHotKey(keyCode: Int, modifiers: UInt32, id: UInt32) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x53544150), id: id) // 'STAP'
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs.append(ref)
        }
    }
    
    public func unregisterHotKeys() {
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
        
        if let local = localMonitor {
            NSEvent.removeMonitor(local)
            localMonitor = nil
        }
    }
    
    deinit {
        // cleanup
    }
}
