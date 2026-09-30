import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var engine = StopwatchEngine()
    @Published public var storage = StorageManager()
    
    // UI state with direct synchronization to Overlay Window Controller
    @Published public var isOverlayVisible: Bool = true {
        didSet {
            OverlayWindowController.shared.toggle(visible: isOverlayVisible)
        }
    }
    @Published public var isFinishingSession: Bool = false
    @Published public var finishingNotes: String = ""
    @Published public var showingDashboard: Bool = false
    @Published public var selectedTab: DashboardTab = .history
    
    public enum DashboardTab: String, CaseIterable {
        case history = "History"
        case tasks = "Tasks"
        case settings = "Settings"
    }
    
    // Last recorded session waiting to be finalized with notes
    @Published public var pendingSession: TimeSession?
    
    // Frontmost / Active open macOS application tracking
    @Published public var frontmostAppName: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private var autoSaveTimer: AnyCancellable?
    
    public init() {
        // Observe engine changes
        engine.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        // Observe storage changes
        storage.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        setupActiveAppTracking()
        setupLifecycleObservers()
    }
    
    private func setupLifecycleObservers() {
        // Periodic auto-snapshot timer (every 4 seconds) to ensure state is never lost even on unexpected exit/crash
        autoSaveTimer = Timer.publish(every: 4.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.engine.state == .running {
                    self.saveCurrentSessionSnapshot()
                }
            }
        
        // Save snapshot before application quits
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.saveCurrentSessionSnapshot()
            }
        }
        
        // Handle macOS sleep
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.storage.data.autoPauseOnSleep && self.engine.state == .running {
                    self.pause()
                }
                self.saveCurrentSessionSnapshot()
            }
        }
    }
    
    private func setupActiveAppTracking() {
        if let current = NSWorkspace.shared.frontmostApplication?.localizedName, !Self.isSelfApp(current) {
            self.frontmostAppName = current
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               let name = app.localizedName,
               !Self.isSelfApp(name) {
                Task { @MainActor [weak self] in
                    self?.frontmostAppName = name
                }
            }
        }
    }
    
    private nonisolated static func isSelfApp(_ name: String) -> Bool {
        let n = name.lowercased()
        return n.contains("stahp") || n.contains("stahpit")
    }
    
    /// Displays either the active app name, task category name, or both
    public var currentHUDTitle: String {
        let taskName = activeTask?.title ?? "No Task"
        let appName = frontmostAppName.isEmpty ? "Finder" : frontmostAppName
        
        switch storage.data.hudDisplayMode {
        case .categoryOnly:
            return taskName
        case .appOnly:
            return appName
        case .both:
            if !frontmostAppName.isEmpty && frontmostAppName != taskName {
                return "\(taskName) • \(appName)"
            }
            return taskName
        }
    }
    
    public var currentHUDIcon: String {
        switch storage.data.hudDisplayMode {
        case .categoryOnly:
            return activeTask?.iconName ?? "timer"
        case .appOnly:
            return "app.badge.checkmark"
        case .both:
            return activeTask?.iconName ?? "timer"
        }
    }
    
    public var activeTask: TaskItem? {
        if let activeId = storage.data.activeTaskId {
            return storage.data.tasks.first(where: { $0.id == activeId })
        }
        return storage.data.tasks.first
    }
    
    public func selectTask(_ task: TaskItem) {
        if engine.state == .running {
            finishCurrentSessionAndSwitch(to: task)
        } else {
            storage.data.activeTaskId = task.id
            storage.save()
        }
    }
    
    public func startOrResume() {
        if activeTask == nil, let first = storage.data.tasks.first {
            storage.data.activeTaskId = first.id
            storage.save()
        }
        engine.start()
    }
    
    public func pause() {
        engine.pause()
    }
    
    public func toggleTimer() {
        if engine.state == .running {
            pause()
        } else {
            startOrResume()
        }
    }
    
    public func recordLap() {
        engine.recordLap()
        saveCurrentSessionSnapshot()
    }
    
    /// Stops the timer, packages the session, and triggers the session completion note dialog
    public func stopAndSaveSession() {
        guard let task = activeTask, engine.elapsedTime > 0 else {
            engine.reset()
            clearSessionSnapshot()
            return
        }
        
        let (duration, laps) = engine.stop()
        clearSessionSnapshot()
        
        let now = Date()
        let start = now.addingTimeInterval(-duration)
        
        let session = TimeSession(
            taskId: task.id,
            taskTitle: task.title,
            taskColorHex: task.colorHex,
            startTime: start,
            endTime: now,
            duration: duration,
            notes: "",
            laps: laps
        )
        
        // Automatically save session to history
        storage.addSession(session)
        pendingSession = session
        finishingNotes = ""
        isFinishingSession = true
    }
    
    public func finishCurrentSessionAndSwitch(to newTask: TaskItem) {
        if engine.elapsedTime > 5 {
            stopAndSaveSession()
        } else {
            engine.reset()
            clearSessionSnapshot()
        }
        storage.data.activeTaskId = newTask.id
        storage.save()
        engine.start()
        saveCurrentSessionSnapshot()
    }
    
    // MARK: - Active Session Persistence & Automatic Restoration
    
    /// Saves the live state of the active stopwatch to persistent disk storage
    public func saveCurrentSessionSnapshot() {
        guard let taskId = storage.data.activeTaskId ?? storage.data.tasks.first?.id else { return }
        
        if let snapshot = engine.currentSnapshot(for: taskId) {
            storage.data.activeSessionSnapshot = snapshot
            storage.save()
        } else if storage.data.activeSessionSnapshot != nil {
            clearSessionSnapshot()
        }
    }
    
    /// Clears any stored session snapshot
    public func clearSessionSnapshot() {
        storage.data.activeSessionSnapshot = nil
        storage.save()
    }
    
    /// Restores the previously active stopwatch session on app launch
    public func restoreSessionIfAvailable() {
        guard storage.data.restoreSessionOnLaunch,
              let snapshot = storage.data.activeSessionSnapshot,
              snapshot.accumulatedDuration > 0 || snapshot.state == "running" else {
            return
        }
        
        // Restore active task category
        if let matchedTask = storage.data.tasks.first(where: { $0.id == snapshot.taskId }) {
            storage.data.activeTaskId = matchedTask.id
        }
        
        // Restore stopwatch engine timing and auto-resume if configured
        engine.restoreFromSnapshot(
            snapshot,
            autoResume: storage.data.autoResumeRunningOnLaunch,
            countOffline: storage.data.countOfflineTime
        )
    }
    
    public func confirmSessionNotes() {
        if let session = pendingSession, !finishingNotes.isEmpty {
            storage.updateSessionNotes(id: session.id, notes: finishingNotes)
        }
        isFinishingSession = false
        pendingSession = nil
        finishingNotes = ""
    }
    
    public func discardPendingSession() {
        if let session = pendingSession {
            storage.deleteSession(id: session.id)
        }
        isFinishingSession = false
        pendingSession = nil
        finishingNotes = ""
    }
    
    public func toggleOverlay() {
        isOverlayVisible.toggle()
    }
    
    public func openSettings(tab: SettingsTab = .general) {
        SettingsWindowController.shared.showSettings(appState: self, tab: tab)
    }
    
    // Global Carbon Hotkey Dispatcher
    public func handleGlobalHotKey(id: UInt32) {
        switch id {
        case 1, 2: // Option + Shift + N (1) or Option + Shift + O (2)
            toggleOverlay()
        case 3:    // Option + Shift + Space
            toggleTimer()
        case 4:    // Option + Shift + S
            stopAndSaveSession()
        default:
            break
        }
    }
}
