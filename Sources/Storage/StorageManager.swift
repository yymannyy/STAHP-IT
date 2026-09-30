import Foundation
import Combine

public enum ScreenAnchor: String, Codable, CaseIterable, Identifiable {
    case notchTopCenter = "Top Notch (MacBook)"
    case topLeft = "Top Left"
    case topRight = "Top Right"
    case leftEdge = "Left Edge (Vertical)"
    case rightEdge = "Right Edge (Vertical)"
    case bottomCenter = "Bottom Center"
    case bottomLeft = "Bottom Left"
    case bottomRight = "Bottom Right"
    case freeFloat = "Free Floating"
    
    public var id: String { rawValue }
    
    public var isVertical: Bool {
        self == .leftEdge || self == .rightEdge
    }
    
    public var iconName: String {
        switch self {
        case .notchTopCenter: return "iphone.and.arrow.forward"
        case .topLeft: return "arrow.up.left.square.fill"
        case .topRight: return "arrow.up.right.square.fill"
        case .leftEdge: return "sidebar.left"
        case .rightEdge: return "sidebar.right"
        case .bottomCenter: return "dock.rectangle"
        case .bottomLeft: return "arrow.down.left.square.fill"
        case .bottomRight: return "arrow.down.right.square.fill"
        case .freeFloat: return "hand.draw.fill"
        }
    }
}

public enum OverlayMode: String, Codable, CaseIterable {
    case notch = "Notch (Dynamic Island)"
    case floating = "Floating Pill"
}

public enum HUDDisplayMode: String, Codable, CaseIterable, Identifiable {
    case categoryOnly = "Category Only"
    case appOnly = "Active App Only"
    case both = "Both (Category & App)"
    
    public var id: String { rawValue }
}

public enum MenuBarDisplayMode: String, Codable, CaseIterable, Identifiable {
    case iconAndTimer = "Icon & Stopwatch"
    case iconOnly = "Icon Only"
    case timerOnly = "Stopwatch Only"
    case fullWithTask = "Icon, Task & Stopwatch"
    
    public var id: String { rawValue }
}

public enum HUDScale: String, Codable, CaseIterable, Identifiable {
    case compact = "Compact"
    case standard = "Standard"
    case large = "Spacious"
    
    public var id: String { rawValue }
    
    public var scaleFactor: CGFloat {
        switch self {
        case .compact: return 0.9
        case .standard: return 1.0
        case .large: return 1.15
        }
    }
}

public enum GlassStyle: String, Codable, CaseIterable, Identifiable {
    case ultraThin = "Ultra-Thin Frost"
    case regular = "Standard Frosted Glass"
    case tintedDark = "Dark Obsidian"
    
    public var id: String { rawValue }
}

public enum AppDisplayLocation: String, Codable, CaseIterable, Identifiable {
    case notchOnly = "Notch HUD / Screen Edge Only"
    case menuBarOnly = "Menu Bar Only"
    case both = "Both (Notch & Menu Bar)"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .notchOnly: return "iphone.and.arrow.forward"
        case .menuBarOnly: return "menubar.rectangle"
        case .both: return "rectangle.topthird.inset.filled"
        }
    }
}

public struct AppData: Codable {
    public var tasks: [TaskItem]
    public var sessions: [TimeSession]
    public var activeTaskId: UUID?
    public var overlayPinned: Bool
    public var overlayMode: OverlayMode
    public var screenAnchor: ScreenAnchor
    public var overlayPositionX: Double?
    public var overlayPositionY: Double?
    public var showMilliseconds: Bool
    public var soundEnabled: Bool
    public var showActiveAppName: Bool
    public var hudDisplayMode: HUDDisplayMode
    public var menuBarDisplayMode: MenuBarDisplayMode
    public var appDisplayLocation: AppDisplayLocation
    public var hudScale: HUDScale
    public var glassStyle: GlassStyle
    public var autoMinimizeToEdge: Bool
    public var autoPauseOnSleep: Bool
    public var idleReminderMinutes: Int
    public var soundOnStartPause: Bool
    public var soundOnSessionComplete: Bool
    public var alwaysShowHours: Bool
    public var flashMenuBarRunning: Bool
    public var launchAtLogin: Bool
    public var promptSessionNotesOnFinish: Bool
    public var restoreSessionOnLaunch: Bool
    public var autoResumeRunningOnLaunch: Bool
    public var countOfflineTime: Bool
    public var activeSessionSnapshot: ActiveSessionSnapshot?
    
    public init(
        tasks: [TaskItem] = TaskItem.defaultPresets,
        sessions: [TimeSession] = [],
        activeTaskId: UUID? = nil,
        overlayPinned: Bool = true,
        overlayMode: OverlayMode = .notch,
        screenAnchor: ScreenAnchor = .notchTopCenter,
        overlayPositionX: Double? = nil,
        overlayPositionY: Double? = nil,
        showMilliseconds: Bool = true,
        soundEnabled: Bool = true,
        showActiveAppName: Bool = true,
        hudDisplayMode: HUDDisplayMode = .categoryOnly,
        menuBarDisplayMode: MenuBarDisplayMode = .iconAndTimer,
        appDisplayLocation: AppDisplayLocation = .notchOnly,
        hudScale: HUDScale = .standard,
        glassStyle: GlassStyle = .ultraThin,
        autoMinimizeToEdge: Bool = true,
        autoPauseOnSleep: Bool = true,
        idleReminderMinutes: Int = 0,
        soundOnStartPause: Bool = true,
        soundOnSessionComplete: Bool = true,
        alwaysShowHours: Bool = true,
        flashMenuBarRunning: Bool = false,
        launchAtLogin: Bool = false,
        promptSessionNotesOnFinish: Bool = true,
        restoreSessionOnLaunch: Bool = true,
        autoResumeRunningOnLaunch: Bool = true,
        countOfflineTime: Bool = false,
        activeSessionSnapshot: ActiveSessionSnapshot? = nil
    ) {
        self.tasks = tasks
        self.sessions = sessions
        self.activeTaskId = activeTaskId ?? tasks.first?.id
        self.overlayPinned = overlayPinned
        self.overlayMode = overlayMode
        self.screenAnchor = screenAnchor
        self.overlayPositionX = overlayPositionX
        self.overlayPositionY = overlayPositionY
        self.showMilliseconds = showMilliseconds
        self.soundEnabled = soundEnabled
        self.showActiveAppName = showActiveAppName
        self.hudDisplayMode = hudDisplayMode
        self.menuBarDisplayMode = menuBarDisplayMode
        self.appDisplayLocation = appDisplayLocation
        self.hudScale = hudScale
        self.glassStyle = glassStyle
        self.autoMinimizeToEdge = autoMinimizeToEdge
        self.autoPauseOnSleep = autoPauseOnSleep
        self.idleReminderMinutes = idleReminderMinutes
        self.soundOnStartPause = soundOnStartPause
        self.soundOnSessionComplete = soundOnSessionComplete
        self.alwaysShowHours = alwaysShowHours
        self.flashMenuBarRunning = flashMenuBarRunning
        self.launchAtLogin = launchAtLogin
        self.promptSessionNotesOnFinish = promptSessionNotesOnFinish
        self.restoreSessionOnLaunch = restoreSessionOnLaunch
        self.autoResumeRunningOnLaunch = autoResumeRunningOnLaunch
        self.countOfflineTime = countOfflineTime
        self.activeSessionSnapshot = activeSessionSnapshot
    }
    
    enum CodingKeys: String, CodingKey {
        case tasks, sessions, activeTaskId, overlayPinned, overlayMode, screenAnchor
        case overlayPositionX, overlayPositionY, showMilliseconds, soundEnabled
        case showActiveAppName, hudDisplayMode, menuBarDisplayMode, appDisplayLocation
        case hudScale, glassStyle
        case autoMinimizeToEdge, autoPauseOnSleep, idleReminderMinutes, soundOnStartPause
        case soundOnSessionComplete, alwaysShowHours, flashMenuBarRunning, launchAtLogin
        case promptSessionNotesOnFinish, restoreSessionOnLaunch, autoResumeRunningOnLaunch
        case countOfflineTime, activeSessionSnapshot
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.tasks = (try? container.decode([TaskItem].self, forKey: .tasks)) ?? TaskItem.defaultPresets
        self.sessions = (try? container.decode([TimeSession].self, forKey: .sessions)) ?? []
        self.activeTaskId = try? container.decode(UUID.self, forKey: .activeTaskId)
        self.overlayPinned = (try? container.decode(Bool.self, forKey: .overlayPinned)) ?? true
        self.overlayMode = (try? container.decode(OverlayMode.self, forKey: .overlayMode)) ?? .notch
        self.screenAnchor = (try? container.decode(ScreenAnchor.self, forKey: .screenAnchor)) ?? .notchTopCenter
        self.overlayPositionX = try? container.decode(Double.self, forKey: .overlayPositionX)
        self.overlayPositionY = try? container.decode(Double.self, forKey: .overlayPositionY)
        self.showMilliseconds = (try? container.decode(Bool.self, forKey: .showMilliseconds)) ?? true
        self.soundEnabled = (try? container.decode(Bool.self, forKey: .soundEnabled)) ?? true
        self.showActiveAppName = (try? container.decode(Bool.self, forKey: .showActiveAppName)) ?? true
        self.hudDisplayMode = (try? container.decode(HUDDisplayMode.self, forKey: .hudDisplayMode)) ?? .categoryOnly
        self.menuBarDisplayMode = (try? container.decode(MenuBarDisplayMode.self, forKey: .menuBarDisplayMode)) ?? .iconAndTimer
        self.appDisplayLocation = (try? container.decode(AppDisplayLocation.self, forKey: .appDisplayLocation)) ?? .notchOnly
        self.hudScale = (try? container.decode(HUDScale.self, forKey: .hudScale)) ?? .standard
        self.glassStyle = (try? container.decode(GlassStyle.self, forKey: .glassStyle)) ?? .ultraThin
        self.autoMinimizeToEdge = (try? container.decode(Bool.self, forKey: .autoMinimizeToEdge)) ?? true
        self.autoPauseOnSleep = (try? container.decode(Bool.self, forKey: .autoPauseOnSleep)) ?? true
        self.idleReminderMinutes = (try? container.decode(Int.self, forKey: .idleReminderMinutes)) ?? 0
        self.soundOnStartPause = (try? container.decode(Bool.self, forKey: .soundOnStartPause)) ?? true
        self.soundOnSessionComplete = (try? container.decode(Bool.self, forKey: .soundOnSessionComplete)) ?? true
        self.alwaysShowHours = (try? container.decode(Bool.self, forKey: .alwaysShowHours)) ?? true
        self.flashMenuBarRunning = (try? container.decode(Bool.self, forKey: .flashMenuBarRunning)) ?? false
        self.launchAtLogin = (try? container.decode(Bool.self, forKey: .launchAtLogin)) ?? false
        self.promptSessionNotesOnFinish = (try? container.decode(Bool.self, forKey: .promptSessionNotesOnFinish)) ?? true
        self.restoreSessionOnLaunch = (try? container.decode(Bool.self, forKey: .restoreSessionOnLaunch)) ?? true
        self.autoResumeRunningOnLaunch = (try? container.decode(Bool.self, forKey: .autoResumeRunningOnLaunch)) ?? true
        self.countOfflineTime = (try? container.decode(Bool.self, forKey: .countOfflineTime)) ?? false
        self.activeSessionSnapshot = try? container.decode(ActiveSessionSnapshot.self, forKey: .activeSessionSnapshot)
    }
}

@MainActor
public final class StorageManager: ObservableObject {
    @Published public var data: AppData
    
    private let fileURL: URL
    
    public init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("StahpIt", isDirectory: true)
        
        try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
        self.fileURL = appFolder.appendingPathComponent("store.json")
        
        if var loadedData = Self.load(from: fileURL) {
            // Ensure new presets (YouTube, Stremio) are present
            let existingTitles = Set(loadedData.tasks.map { $0.title.lowercased() })
            if !existingTitles.contains("youtube") {
                loadedData.tasks.append(TaskItem(title: "YouTube", colorHex: "#EF4444", iconName: "play.rectangle.fill"))
            }
            if !existingTitles.contains("stremio") {
                loadedData.tasks.append(TaskItem(title: "Stremio", colorHex: "#8B5CF6", iconName: "film.fill"))
            }
            self.data = loadedData
            self.save()
        } else {
            self.data = AppData()
            self.save()
        }
    }
    
    public func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let rawData = try encoder.encode(data)
            try rawData.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save StahpIt data: \(error)")
        }
    }
    
    private static func load(from url: URL) -> AppData? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let rawData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(AppData.self, from: rawData)
        } catch {
            print("Failed to decode StahpIt data from \(url): \(error)")
            return nil
        }
    }
    
    public func resetToDefaults() {
        let currentTasks = data.tasks
        let currentSessions = data.sessions
        self.data = AppData(tasks: currentTasks, sessions: currentSessions)
        save()
    }
    
    public func clearAllHistory() {
        self.data.sessions.removeAll()
        save()
    }
    
    // MARK: - Task Operations
    
    public func addTask(_ task: TaskItem) {
        data.tasks.append(task)
        save()
    }
    
    public func updateTask(_ task: TaskItem) {
        if let index = data.tasks.firstIndex(where: { $0.id == task.id }) {
            data.tasks[index] = task
            save()
        }
    }
    
    public func deleteTask(id: UUID) {
        data.tasks.removeAll { $0.id == id }
        if data.activeTaskId == id {
            data.activeTaskId = data.tasks.first?.id
        }
        save()
    }
    
    public func restoreDefaultTasks() {
        self.data.tasks = TaskItem.defaultPresets
        if let first = TaskItem.defaultPresets.first {
            self.data.activeTaskId = first.id
        }
        save()
    }
    
    // MARK: - Session Operations
    
    public func addSession(_ session: TimeSession) {
        data.sessions.insert(session, at: 0) // Newest first
        save()
    }
    
    public func deleteSession(id: UUID) {
        data.sessions.removeAll { $0.id == id }
        save()
    }
    
    public func updateSessionNotes(id: UUID, notes: String) {
        if let index = data.sessions.firstIndex(where: { $0.id == id }) {
            data.sessions[index].notes = notes
            save()
        }
    }
    
    // MARK: - Exporters
    
    public func exportToCSV() -> String {
        var csv = "Session ID,Task Name,Start Time,End Time,Duration (Seconds),Duration (Formatted),Notes\n"
        let df = ISO8601DateFormatter()
        
        for session in data.sessions {
            let safeTitle = sanitizeCSVCell(session.taskTitle)
            let safeNotes = sanitizeCSVCell(session.notes)
            let start = df.string(from: session.startTime)
            let end = df.string(from: session.endTime)
            let durationSec = Int(session.duration)
            let formattedDur = TimeFormatter.formatHumanDuration(session.duration)
            
            csv += "\(session.id.uuidString),\(safeTitle),\(start),\(end),\(durationSec),\(formattedDur),\(safeNotes)\n"
        }
        return csv
    }
    
    private func sanitizeCSVCell(_ input: String) -> String {
        var sanitized = input.replacingOccurrences(of: "\"", with: "\"\"")
        // Defend against CSV injection (formula execution in Excel/Numbers)
        if sanitized.starts(with: "=") || sanitized.starts(with: "+") || sanitized.starts(with: "-") || sanitized.starts(with: "@") || sanitized.starts(with: "\t") {
            sanitized = "'" + sanitized
        }
        return "\"\(sanitized)\""
    }
    
    public func exportToJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let raw = try? encoder.encode(data.sessions), let str = String(data: raw, encoding: .utf8) {
            return str
        }
        return "[]"
    }
    
    public func exportToMarkdown() -> String {
        var md = "# STAHP IT! Task Worklog\n\n"
        md += "Generated on: \(Date().formatted(date: .abbreviated, time: .shortened))\n\n"
        
        // Group by day
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: data.sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }.sorted { $0.key > $1.key }
        
        for (day, sessions) in grouped {
            let dayTotal = sessions.reduce(0) { $0 + $1.duration }
            md += "## \(TimeFormatter.formatDayHeader(day)) (Total: \(TimeFormatter.formatHumanDuration(dayTotal)))\n\n"
            md += "| Time | Task | Duration | Notes |\n"
            md += "| :--- | :--- | :--- | :--- |\n"
            
            for s in sessions {
                let timeStr = "\(DateFormatter.localizedString(from: s.startTime, dateStyle: .none, timeStyle: .short)) - \(DateFormatter.localizedString(from: s.endTime, dateStyle: .none, timeStyle: .short))"
                let safeTitle = s.taskTitle.replacingOccurrences(of: "|", with: "\\|")
                let notesStr = s.notes.isEmpty ? "-" : s.notes.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "|", with: "\\|")
                md += "| \(timeStr) | **\(safeTitle)** | `\(TimeFormatter.formatHumanDuration(s.duration))` | \(notesStr) |\n"
            }
            md += "\n"
        }
        return md
    }
}
