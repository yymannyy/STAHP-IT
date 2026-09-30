import Foundation

public struct LapRecord: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var lapNumber: Int
    public var splitTime: TimeInterval // Time for this specific lap
    public var totalTime: TimeInterval // Elapsed time when lap was recorded
    public var timestamp: Date
    
    public init(
        id: UUID = UUID(),
        lapNumber: Int,
        splitTime: TimeInterval,
        totalTime: TimeInterval,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.lapNumber = lapNumber
        self.splitTime = splitTime
        self.totalTime = totalTime
        self.timestamp = timestamp
    }
}

public struct TimeSession: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var taskId: UUID
    public var taskTitle: String
    public var taskColorHex: String
    public var startTime: Date
    public var endTime: Date
    public var duration: TimeInterval
    public var notes: String
    public var laps: [LapRecord]
    
    public init(
        id: UUID = UUID(),
        taskId: UUID,
        taskTitle: String,
        taskColorHex: String = "#0A84FF",
        startTime: Date,
        endTime: Date = Date(),
        duration: TimeInterval,
        notes: String = "",
        laps: [LapRecord] = []
    ) {
        self.id = id
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.taskColorHex = taskColorHex
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.notes = notes
        self.laps = laps
    }
}

public struct ActiveSessionSnapshot: Codable, Equatable {
    public var taskId: UUID
    public var state: String // "running", "paused", "idle"
    public var accumulatedDuration: TimeInterval
    public var sessionStartTime: Date?
    public var lastSnapshotDate: Date
    public var laps: [LapRecord]
    
    public init(
        taskId: UUID,
        state: String,
        accumulatedDuration: TimeInterval,
        sessionStartTime: Date? = nil,
        lastSnapshotDate: Date = Date(),
        laps: [LapRecord] = []
    ) {
        self.taskId = taskId
        self.state = state
        self.accumulatedDuration = accumulatedDuration
        self.sessionStartTime = sessionStartTime
        self.lastSnapshotDate = lastSnapshotDate
        self.laps = laps
    }
}
