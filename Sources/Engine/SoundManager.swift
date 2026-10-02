import AppKit

/// Plays native macOS system sounds for timer events.
/// Respects the master `soundEnabled` toggle and per-event settings from `AppData`.
@MainActor
public final class SoundManager {
    public static let shared = SoundManager()
    
    public enum SoundEvent {
        case start
        case pause
        case resume
        case lap
        case sessionComplete
    }
    
    private init() {}
    
    /// Play the appropriate system sound for a timer event.
    /// - Parameters:
    ///   - event: The timer event that occurred.
    ///   - data: The current AppData to check sound preference toggles.
    public func play(_ event: SoundEvent, data: AppData) {
        guard data.soundEnabled else { return }
        
        switch event {
        case .start, .pause, .resume:
            guard data.soundOnStartPause else { return }
        case .sessionComplete:
            guard data.soundOnSessionComplete else { return }
        case .lap:
            guard data.soundOnStartPause else { return }
        }
        
        let soundName = systemSoundName(for: event)
        NSSound(named: soundName)?.play()
    }
    
    private func systemSoundName(for event: SoundEvent) -> NSSound.Name {
        switch event {
        case .start:           return "Tink"
        case .pause:           return "Pop"
        case .resume:          return "Tink"
        case .lap:             return "Morse"
        case .sessionComplete: return "Glass"
        }
    }
}
