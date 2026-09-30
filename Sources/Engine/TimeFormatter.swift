import Foundation

public enum TimeFormatter {
    /// Formats seconds into `HH:MM:SS` or `MM:SS` (e.g. 01:23:45 or 05:12)
    public static func formatStopwatch(
        _ timeInterval: TimeInterval,
        includeTenths: Bool = false,
        alwaysIncludeHours: Bool = false
    ) -> String {
        let totalSeconds = max(0, Int(timeInterval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        let tenths = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 10)
        
        if hours > 0 || alwaysIncludeHours {
            if includeTenths {
                return String(format: "%02d:%02d:%02d.%01d", hours, minutes, seconds, tenths)
            } else {
                return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            }
        } else {
            if includeTenths {
                return String(format: "%02d:%02d.%01d", minutes, seconds, tenths)
            } else {
                return String(format: "%02d:%02d", minutes, seconds)
            }
        }
    }
    
    /// Returns split components for vertical edge display (e.g. ["05", "42"] or ["01", "23", "45"])
    public static func formatVerticalComponents(_ timeInterval: TimeInterval) -> [String] {
        let totalSeconds = max(0, Int(timeInterval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return [String(format: "%02d", hours), String(format: "%02d", minutes), String(format: "%02d", seconds)]
        } else {
            return [String(format: "%02d", minutes), String(format: "%02d", seconds)]
        }
    }
    
    /// Formats seconds into human-friendly duration like "1h 45m" or "23m 10s"
    public static func formatHumanDuration(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(timeInterval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        } else if minutes > 0 {
            if seconds > 0 {
                return "\(minutes)m \(seconds)s"
            }
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Date formatter for daily grouping in logs
    public static func formatSessionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today, " + DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, " + DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
        } else {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .short
            return df.string(from: date)
        }
    }
    
    /// Day grouping header (e.g., "Today", "Yesterday", "Monday, Sep 28")
    public static func formatDayHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let df = DateFormatter()
            df.dateFormat = "EEEE, MMM d"
            return df.string(from: date)
        }
    }
}
