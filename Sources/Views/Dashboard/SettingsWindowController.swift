import AppKit
import SwiftUI

@MainActor
public final class SettingsWindowController: NSObject, NSWindowDelegate {
    public static let shared = SettingsWindowController()
    
    private var window: NSWindow?
    
    public override init() {
        super.init()
    }
    
    public func showSettings(appState: AppState, tab: SettingsTab = .general) {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsDialogView(appState: appState, initialTab: tab)
        let hostingView = NSHostingView(rootView: settingsView)
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 740, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        newWindow.title = "STAHP IT! Settings"
        newWindow.titleVisibility = .visible
        newWindow.titlebarAppearsTransparent = false
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.contentView = hostingView
        newWindow.center()
        newWindow.setFrameAutosaveName("StahpItSettingsWindow")
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func windowWillClose(_ notification: Notification) {
        self.window = nil
    }
}
