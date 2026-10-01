import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let appState = AppState.shared
        
        // Restore active session state (or resume stopwatch) if previous session existed
        appState.restoreSessionIfAvailable()
        
        // Setup Floating Overlay Window (Top Notch / Screen Edge)
        OverlayWindowController.shared.setup(appState: appState)
        
        // Sync display location (Notch vs Menu Bar)
        appState.syncDisplayLocations()
        
        // Setup Carbon & Local Hotkeys
        HotkeyManager.shared.setup(appState: appState)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        AppState.shared.saveCurrentSessionSnapshot()
    }
}

@main
struct StahpItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        // Menu Bar Extra
        MenuBarExtra {
            MenuBarView(appState: appState)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: appState.engine.state == .running ? "stopwatch.fill" : "stopwatch")
                
                if appState.storage.data.appDisplayLocation != .notchOnly && appState.engine.state != .idle {
                    Text(TimeFormatter.formatStopwatch(appState.engine.elapsedTime))
                        .font(.system(.body, design: .monospaced))
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
        
        // Dashboard Window
        Window("STAHP IT! Dashboard", id: "dashboard") {
            DashboardWindowView(appState: appState)
                .onChange(of: appState.showingDashboard) { _, showing in
                    if showing {
                        openWindow(id: "dashboard")
                        appState.showingDashboard = false
                    }
                }
        }
        .defaultSize(width: 800, height: 550)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    appState.openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            
            CommandGroup(after: .appSettings) {
                Button("Dashboard & History") {
                    appState.showingDashboard = true
                    NSApp.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }
    }
}
