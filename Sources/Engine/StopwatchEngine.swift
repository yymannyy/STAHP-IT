import Foundation
import Combine

public enum StopwatchState: String, Codable {
    case idle
    case running
    case paused
}

@MainActor
public final class StopwatchEngine: ObservableObject {
    @Published public private(set) var state: StopwatchState = .idle
    @Published public private(set) var elapsedTime: TimeInterval = 0
    @Published public private(set) var laps: [LapRecord] = []
    
    // Internal reference timestamps
    private var startTime: Date?
    private var accumulatedDuration: TimeInterval = 0
    private var lastLapTotalTime: TimeInterval = 0
    
    private var timerCancellable: AnyCancellable?
    
    public init() {}
    
    /// Starts or resumes the stopwatch
    public func start() {
        guard state != .running else { return }
        
        startTime = Date()
        state = .running
        startTickPublisher()
    }
    
    /// Pauses the stopwatch and preserves accumulated elapsed time
    public func pause() {
        guard state == .running else { return }
        
        if let start = startTime {
            accumulatedDuration += Date().timeIntervalSince(start)
        }
        startTime = nil
        elapsedTime = accumulatedDuration
        state = .paused
        stopTickPublisher()
    }
    
    /// Resumes the stopwatch from paused state
    public func resume() {
        guard state == .paused else { return }
        start()
    }
    
    /// Toggles between start/resume and pause
    public func toggle() {
        switch state {
        case .idle:
            start()
        case .running:
            pause()
        case .paused:
            resume()
        }
    }
    
    /// Records a lap
    public func recordLap() {
        guard state != .idle else { return }
        
        updateElapsedTime()
        let currentTotal = elapsedTime
        let split = currentTotal - lastLapTotalTime
        lastLapTotalTime = currentTotal
        
        let newLap = LapRecord(
            lapNumber: laps.count + 1,
            splitTime: split,
            totalTime: currentTotal,
            timestamp: Date()
        )
        laps.insert(newLap, at: 0) // newest first
    }
    
    /// Stops the timer and returns the final duration & recorded laps
    public func stop() -> (duration: TimeInterval, laps: [LapRecord]) {
        updateElapsedTime()
        let finalDuration = elapsedTime
        let finalLaps = laps
        
        reset()
        return (finalDuration, finalLaps)
    }
    
    /// Resets all timing and state back to idle
    public func reset() {
        stopTickPublisher()
        state = .idle
        elapsedTime = 0
        accumulatedDuration = 0
        lastLapTotalTime = 0
        startTime = nil
        laps.removeAll()
    }
    
    // MARK: - Snapshot Restoration & Auto-Resume
    
    /// Restores the stopwatch state from a saved snapshot
    public func restoreFromSnapshot(
        _ snapshot: ActiveSessionSnapshot,
        autoResume: Bool = true,
        countOffline: Bool = false
    ) {
        var restoredDuration = snapshot.accumulatedDuration
        
        // If it was running when app closed and user chose to count offline time
        if snapshot.state == "running" && countOffline {
            let offlineSeconds = max(0, Date().timeIntervalSince(snapshot.lastSnapshotDate))
            restoredDuration += offlineSeconds
        }
        
        self.accumulatedDuration = restoredDuration
        self.elapsedTime = restoredDuration
        self.laps = snapshot.laps
        self.lastLapTotalTime = snapshot.laps.first?.totalTime ?? 0
        
        if snapshot.state == "running" && autoResume {
            self.startTime = Date()
            self.state = .running
            startTickPublisher()
        } else if restoredDuration > 0 {
            self.state = .paused
            self.startTime = nil
            stopTickPublisher()
        } else {
            self.state = .idle
            self.startTime = nil
            stopTickPublisher()
        }
    }
    
    /// Generates an active snapshot of the current stopwatch state
    public func currentSnapshot(for taskId: UUID) -> ActiveSessionSnapshot? {
        guard state != .idle || elapsedTime > 0 else { return nil }
        
        var currentAcc = accumulatedDuration
        if state == .running, let start = startTime {
            currentAcc += Date().timeIntervalSince(start)
        }
        
        return ActiveSessionSnapshot(
            taskId: taskId,
            state: state.rawValue,
            accumulatedDuration: currentAcc,
            sessionStartTime: startTime,
            lastSnapshotDate: Date(),
            laps: laps
        )
    }
    
    // MARK: - Internal Ticking Loop
    
    private func startTickPublisher() {
        stopTickPublisher()
        // Synchronized high refresh rate tick publisher (60-120Hz ProMotion compatible)
        timerCancellable = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateElapsedTime()
            }
    }
    
    private func stopTickPublisher() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func updateElapsedTime() {
        guard state == .running, let start = startTime else { return }
        let currentSegment = Date().timeIntervalSince(start)
        elapsedTime = accumulatedDuration + currentSegment
    }
}
