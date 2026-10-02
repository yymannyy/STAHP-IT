import Foundation
import UserNotifications

/// Manages local notifications for idle/continuous task reminders.
/// Requests notification authorization and posts alerts when the stopwatch
/// exceeds the user-configured threshold.
@MainActor
public final class NotificationManager {
    public static let shared = NotificationManager()
    
    private var hasRequestedAuth = false
    private var hasRemindedForCurrentSession = false
    
    private init() {}
    
    /// Request notification permission. Safe to call multiple times — only
    /// actually prompts the user on first invocation.
    public func requestAuthorizationIfNeeded() {
        guard !hasRequestedAuth else { return }
        hasRequestedAuth = true
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }
    
    /// Call this when a new stopwatch session starts or resumes to reset the
    /// one-shot reminder flag.
    public func resetReminderFlag() {
        hasRemindedForCurrentSession = false
    }
    
    /// Check whether the elapsed time has crossed the idle reminder threshold
    /// and fire a notification if so.
    /// - Parameters:
    ///   - elapsedTime: Current stopwatch elapsed time in seconds.
    ///   - reminderMinutes: The user's chosen threshold (0 = disabled).
    ///   - taskName: Name of the active task category for the notification body.
    public func checkAndNotifyIfNeeded(elapsedTime: TimeInterval, reminderMinutes: Int, taskName: String) {
        guard reminderMinutes > 0, !hasRemindedForCurrentSession else { return }
        
        let thresholdSeconds = TimeInterval(reminderMinutes * 60)
        guard elapsedTime >= thresholdSeconds else { return }
        
        hasRemindedForCurrentSession = true
        postIdleReminder(taskName: taskName, minutes: reminderMinutes)
    }
    
    private func postIdleReminder(taskName: String, minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🛑 Still tracking: \(taskName)"
        
        let hours = minutes / 60
        let mins = minutes % 60
        let durationText: String
        if hours > 0 && mins > 0 {
            durationText = "\(hours)h \(mins)m"
        } else if hours > 0 {
            durationText = "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            durationText = "\(mins) minutes"
        }
        content.body = "You've been on this task for \(durationText). Take a break or finish the session."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "stahpit.idle.\(UUID().uuidString)",
            content: content,
            trigger: nil // Fire immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to post idle reminder: \(error)")
            }
        }
    }
}
