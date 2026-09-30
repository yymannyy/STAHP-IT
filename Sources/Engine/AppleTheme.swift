import SwiftUI
import AppKit

public enum AppleTheme {
    // Apple Design Tokens (apple.md)
    public static let actionBlue = Color(hex: "#0071E3") ?? Color.blue
    public static let actionBluePrimary = Color(hex: "#0066CC") ?? Color.blue
    public static let skyLinkBlue = Color(hex: "#2997FF") ?? Color.blue
    public static let trueBlack = Color(hex: "#000000") ?? Color.black
    public static let ink = Color(hex: "#1D1D1F") ?? Color.black
    public static let canvasParchment = Color(hex: "#F5F5F7") ?? Color(nsColor: .windowBackgroundColor)
    public static let surfaceTile1 = Color(hex: "#272729") ?? Color(nsColor: .controlBackgroundColor)
    public static let surfaceTile2 = Color(hex: "#2A2A2C") ?? Color(nsColor: .controlBackgroundColor)
    public static let hairline = Color(hex: "#E0E0E0") ?? Color.gray.opacity(0.2)
    public static let hairlineDark = Color.white.opacity(0.12)
    
    // Radii
    public static let radiusSm: CGFloat = 8
    public static let radiusMd: CGFloat = 11
    public static let radiusLg: CGFloat = 18
    // Modern Apple Fluid Spring Animation Presets (macOS 14+ / ProMotion Calibrated)
    public static let springBouncy: Animation = .spring(response: 0.38, dampingFraction: 0.82)
    public static let springSnappy: Animation = .spring(response: 0.28, dampingFraction: 0.86)
    public static let springSmooth: Animation = .spring(response: 0.40, dampingFraction: 0.90)
    public static let springHover: Animation = .spring(response: 0.26, dampingFraction: 0.88)
    public static let springGentle: Animation = .spring(response: 0.48, dampingFraction: 0.92)
}

// Apple Press Micro-Interaction ButtonStyle
public struct ApplePillButtonStyle: ButtonStyle {
    var backgroundColor: Color = AppleTheme.actionBlue
    var foregroundColor: Color = .white
    var isCompact: Bool = false
    
    public init(backgroundColor: Color = AppleTheme.actionBlue, foregroundColor: Color = .white, isCompact: Bool = false) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.isCompact = isCompact
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: isCompact ? 11 : 13, weight: .semibold, design: .default))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, isCompact ? 10 : 16)
            .padding(.vertical, isCompact ? 5 : 8)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(AppleTheme.springSnappy, value: configuration.isPressed)
    }
}

public struct AppleSecondaryPillStyle: ButtonStyle {
    var isCompact: Bool = false
    
    public init(isCompact: Bool = false) {
        self.isCompact = isCompact
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: isCompact ? 11 : 13, weight: .medium))
            .foregroundColor(.primary)
            .padding(.horizontal, isCompact ? 10 : 14)
            .padding(.vertical, isCompact ? 5 : 7)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(0.08))
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(AppleTheme.springSnappy, value: configuration.isPressed)
    }
}

// Dynamic Responsive Notch Geometry for MacBook Pro (M1 Pro, M2, M3, M4)
public enum NotchGeometry {
    public static func hasHardwareNotch(screen: NSScreen? = NSScreen.main) -> Bool {
        guard let screen = screen else { return false }
        return screen.safeAreaInsets.top > 0 || screen.auxiliaryTopLeftArea != nil
    }
    
    public static func notchHeight(screen: NSScreen? = NSScreen.main) -> CGFloat {
        guard let screen = screen else { return 38 }
        let safeTop = screen.safeAreaInsets.top
        return safeTop > 0 ? safeTop : 38
    }
    
    public static func notchWidth(screen: NSScreen? = NSScreen.main) -> CGFloat {
        guard let screen = screen else { return 220 }
        if let leftArea = screen.auxiliaryTopLeftArea, let rightArea = screen.auxiliaryTopRightArea {
            let gap = rightArea.minX - leftArea.maxX
            if gap > 100 && gap < 400 {
                return gap
            }
        }
        return 220
    }
    
    /// Responsive symmetrical wing width for left (task/app) and right (stopwatch) sides of the notch
    public static func responsiveWingWidth(title: String, screen: NSScreen? = NSScreen.main) -> CGFloat {
        let baseMin: CGFloat = 145.0
        // Estimate width based on character count (11pt SF Pro bold ~ 7.2pt per char + dot & icon + padding)
        let estimatedTextWidth: CGFloat = CGFloat(title.count) * 7.2 + 56.0
        
        let screenW = screen?.frame.width ?? 1800.0
        let notchW = notchWidth(screen: screen)
        let maxWing = max(baseMin, (screenW - notchW - 160.0) / 2.0)
        
        return max(baseMin, min(estimatedTextWidth, maxWing))
    }
    
    public static func wingWidth(screen: NSScreen? = NSScreen.main) -> CGFloat {
        return 145.0
    }
    
    public static func totalWidth(title: String? = nil, screen: NSScreen? = NSScreen.main) -> CGFloat {
        let wingW = title != nil ? responsiveWingWidth(title: title!, screen: screen) : wingWidth(screen: screen)
        return notchWidth(screen: screen) + (2 * wingW)
    }
}
