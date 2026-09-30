import Foundation
import SwiftUI

public struct TaskItem: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var title: String
    public var colorHex: String
    public var iconName: String
    public var isArchived: Bool
    public var createdAt: Date
    public var targetMinutes: Int? // Optional goal per day/session
    
    public init(
        id: UUID = UUID(),
        title: String,
        colorHex: String = "#0A84FF",
        iconName: String = "timer",
        isArchived: Bool = false,
        createdAt: Date = Date(),
        targetMinutes: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.colorHex = colorHex
        self.iconName = iconName
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.targetMinutes = targetMinutes
    }
    
    public var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    public static let defaultPresets: [TaskItem] = [
        TaskItem(title: "Deep Work", colorHex: "#6366F1", iconName: "brain.head.profile"),
        TaskItem(title: "Coding & Dev", colorHex: "#10B981", iconName: "chevron.left.forwardslash.chevron.right"),
        TaskItem(title: "YouTube", colorHex: "#EF4444", iconName: "play.rectangle.fill"),
        TaskItem(title: "Stremio", colorHex: "#8B5CF6", iconName: "film.fill"),
        TaskItem(title: "Design & UI", colorHex: "#EC4899", iconName: "paintpalette.fill"),
        TaskItem(title: "Meetings & Calls", colorHex: "#F59E0B", iconName: "person.2.fill"),
        TaskItem(title: "Writing & Docs", colorHex: "#3B82F6", iconName: "doc.text.fill"),
        TaskItem(title: "General", colorHex: "#64748B", iconName: "checklist")
    ]
}

// Color hex helper
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        let r, g, b, a: Double
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    func toHex() -> String {
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            return "#0A84FF"
        }
        let r = Int(round(rgbColor.redComponent * 255))
        let g = Int(round(rgbColor.greenComponent * 255))
        let b = Int(round(rgbColor.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
