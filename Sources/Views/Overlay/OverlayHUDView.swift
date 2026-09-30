import SwiftUI

@MainActor
public final class OverlayViewState: ObservableObject {
    @Published public var isHovered: Bool = false
    @Published public var isExpanded: Bool = false
    public init() {}
}

public struct OverlayHUDView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewState = OverlayViewState()
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        Group {
            if appState.storage.data.screenAnchor == .notchTopCenter {
                notchDynamicIslandView
            } else if appState.storage.data.screenAnchor.isVertical {
                verticalEdgePillView
            } else {
                horizontalEdgePillView
            }
        }
        .animation(AppleTheme.springSnappy, value: appState.storage.data.screenAnchor)
        .sensoryFeedback(.selection, trigger: appState.engine.state)
        .sensoryFeedback(.impact(weight: .light), trigger: appState.engine.laps.count)
    }
    
    // MARK: - MacBook Pro Notch Dynamic Island View
    
    private var notchDynamicIslandView: some View {
        let task = appState.activeTask
        let taskColor = task?.color ?? AppleTheme.actionBlue
        let isRunning = appState.engine.state == .running
        let isExpanded = viewState.isHovered || viewState.isExpanded
        let hudTitle = appState.currentHUDTitle
        
        let screen = NSScreen.main
        let notchW = NotchGeometry.notchWidth(screen: screen) // 220 pt
        let notchH = NotchGeometry.notchHeight(screen: screen) // 38 pt
        let wingW = NotchGeometry.responsiveWingWidth(title: hudTitle, screen: screen) // Symmetrical responsive width
        
        let islandW: CGFloat = isExpanded ? max(460, notchW + (2 * wingW)) : (notchW + (2 * wingW))
        let expandedH: CGFloat = 154
        let currentH: CGFloat = isExpanded ? expandedH : notchH
        
        return VStack(spacing: 0) {
            ZStack(alignment: .top) {
                // Background Island Body (True Black with Apple continuous curvature)
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: isExpanded ? 24 : 14,
                    bottomTrailingRadius: isExpanded ? 24 : 14,
                    topTrailingRadius: 0,
                    style: .continuous
                )
                .fill(AppleTheme.trueBlack)
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: isExpanded ? 24 : 14,
                        bottomTrailingRadius: isExpanded ? 24 : 14,
                        topTrailingRadius: 0,
                        style: .continuous
                    )
                    .stroke(Color.white.opacity(isExpanded ? 0.18 : 0.10), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(isExpanded ? 0.65 : 0.0), radius: isExpanded ? 24 : 0, x: 0, y: isExpanded ? 12 : 0)
                
                // Native Apple Light Animation Element — ONLY shows when hovering over the notch
                if viewState.isHovered {
                    NotchLightContourView(
                        taskColor: taskColor,
                        isRunning: isRunning,
                        isExpanded: isExpanded,
                        islandW: islandW,
                        currentH: currentH
                    )
                    .transition(.opacity)
                }
                
                VStack(spacing: 0) {
                    // Top Notch Bar (Responsive Equal Left Wing | Center Notch Gap | Responsive Equal Right Wing)
                    HStack(spacing: 0) {
                        // 1. Left Wing: Ends right at the notch's left boundary
                        Group {
                            if isExpanded {
                                Menu {
                                    ForEach(appState.storage.data.tasks) { t in
                                        Button {
                                            appState.selectTask(t)
                                        } label: {
                                            HStack {
                                                Image(systemName: t.iconName)
                                                Text(t.title)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        PulsingTaskDot(color: taskColor, isPulsing: isRunning)
                                        
                                        Image(systemName: appState.currentHUDIcon)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.9))
                                            .symbolEffect(.bounce, value: task?.id)
                                        
                                        Text(hudTitle)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 7, weight: .bold))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3.5)
                                    .background(Capsule().fill(Color.white.opacity(0.12)))
                                }
                                .menuStyle(.borderlessButton)
                                .fixedSize()
                            } else {
                                HStack(spacing: 6) {
                                    PulsingTaskDot(color: taskColor, isPulsing: isRunning)
                                    
                                    Image(systemName: appState.currentHUDIcon)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                        .symbolEffect(.bounce, value: task?.id)
                                    
                                    Text(hudTitle)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.leading, 12)
                        .padding(.trailing, 10)
                        .frame(width: isExpanded ? ((islandW - notchW) / 2) : wingW, height: notchH, alignment: .trailing)
                        
                        // 2. Center Camera Notch Gap (220pt)
                        Color.clear
                            .frame(width: notchW, height: notchH)
                        
                        // 3. Right Wing: Starts right from the notch's right boundary
                        Group {
                            if isExpanded {
                                HStack(spacing: 6) {
                                    // Animated Running/Paused badge
                                    Text(appState.engine.state.rawValue.uppercased())
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2.5)
                                        .background(
                                            Capsule().fill(isRunning ? Color.green.opacity(0.25) : Color.white.opacity(0.12))
                                        )
                                        .foregroundColor(isRunning ? .green : .secondary)
                                    
                                    // Edge Anchor Picker
                                    Menu {
                                        ForEach(ScreenAnchor.allCases) { anchor in
                                            Button {
                                                OverlayWindowController.shared.snapToAnchor(anchor, appState: appState)
                                            } label: {
                                                HStack {
                                                    Image(systemName: anchor.iconName)
                                                    Text(anchor.rawValue)
                                                }
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.8))
                                            .padding(4)
                                    }
                                    .menuStyle(.borderlessButton)
                                    .fixedSize()
                                    .help("Snap Overlay to Screen Edge")
                                }
                            } else {
                                HStack(spacing: 5) {
                                    if isRunning {
                                        Image(systemName: "stopwatch.fill")
                                            .font(.system(size: 9))
                                            .foregroundColor(taskColor)
                                            .symbolEffect(.pulse, isActive: isRunning)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                    
                                    Text(TimeFormatter.formatStopwatch(appState.engine.elapsedTime, includeTenths: true))
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .monospacedDigit()
                                        .contentTransition(.numericText(value: appState.engine.elapsedTime))
                                        .foregroundColor(isRunning ? .white : Color(hex: "#A1A1A6")!)
                                }
                            }
                        }
                        .padding(.leading, 10)
                        .padding(.trailing, 12)
                        .frame(width: isExpanded ? ((islandW - notchW) / 2) : wingW, height: notchH, alignment: .leading)
                    }
                    .frame(width: islandW, height: notchH)
                    
                    // Expanded Dropdown Area (below physical notch)
                    if isExpanded {
                        VStack(spacing: 10) {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 16)
                            
                            // Center Hero Monospaced Stopwatch Digits
                            HStack(alignment: .lastTextBaseline, spacing: 8) {
                                Text(TimeFormatter.formatStopwatch(appState.engine.elapsedTime, includeTenths: true, alwaysIncludeHours: true))
                                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                                    .monospacedDigit()
                                    .contentTransition(.numericText(value: appState.engine.elapsedTime))
                                    .foregroundColor(.white)
                                    .tracking(-0.374)
                                
                                if !appState.engine.laps.isEmpty {
                                    Text("\(appState.engine.laps.count) laps")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(AppleTheme.skyLinkBlue)
                                        .transition(.opacity)
                                }
                            }
                            
                            // Bottom Action Controls
                            HStack(spacing: 12) {
                                // Reset
                                BouncyIconButton(
                                    icon: "arrow.counterclockwise",
                                    size: 30,
                                    isEnabled: appState.engine.elapsedTime > 0
                                ) {
                                    appState.engine.reset()
                                }
                                
                                // Primary Action Blue Play/Pause
                                Button {
                                    appState.toggleTimer()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                            .font(.system(size: 12, weight: .bold))
                                            .symbolEffect(.bounce, value: isRunning)
                                        Text(isRunning ? "Pause" : (appState.engine.elapsedTime > 0 ? "Resume" : "Start"))
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .frame(height: 30)
                                    .background(
                                        Capsule().fill(isRunning ? Color.orange : AppleTheme.actionBlue)
                                    )
                                }
                                .buttonStyle(BouncyButtonStyle())
                                
                                // Record Lap
                                BouncyIconButton(
                                    icon: "flag.fill",
                                    size: 30,
                                    isEnabled: appState.engine.state != .idle
                                ) {
                                    appState.recordLap()
                                }
                                
                                // Finish & Save Session
                                BouncyIconButton(
                                    icon: "checkmark",
                                    size: 30,
                                    backgroundColor: Color.green.opacity(0.85),
                                    isEnabled: appState.engine.elapsedTime > 0
                                ) {
                                    appState.stopAndSaveSession()
                                }
                                
                                // Open Settings Dialog
                                BouncyIconButton(
                                    icon: "gearshape.fill",
                                    size: 30,
                                    backgroundColor: Color.white.opacity(0.12),
                                    isEnabled: true
                                ) {
                                    appState.openSettings()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                        ))
                    }
                }
            }
            .frame(width: islandW, height: currentH)
            .animation(AppleTheme.springSmooth, value: isExpanded)
            .onHover { hovering in
                withAnimation(AppleTheme.springSmooth) {
                    viewState.isHovered = hovering
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Horizontal Edge / Screen Docked Pill View (Top & Bottom Edges)
    
    private var horizontalEdgePillView: some View {
        let task = appState.activeTask
        let taskColor = task?.color ?? AppleTheme.actionBlue
        let isRunning = appState.engine.state == .running
        
        return HStack(spacing: 8) {
            // Task Indicator & Switcher
            Menu {
                Section("Active Task") {
                    ForEach(appState.storage.data.tasks) { t in
                        Button {
                            appState.selectTask(t)
                        } label: {
                            HStack {
                                Image(systemName: t.iconName)
                                Text(t.title)
                            }
                        }
                    }
                }
                
                Section("Snap to Screen Edge") {
                    ForEach(ScreenAnchor.allCases) { anchor in
                        Button {
                            OverlayWindowController.shared.snapToAnchor(anchor, appState: appState)
                        } label: {
                            HStack {
                                Image(systemName: anchor.iconName)
                                Text(anchor.rawValue)
                            }
                        }
                    }
                }
                
                Section("Preferences") {
                    Button {
                        appState.openSettings()
                    } label: {
                        HStack {
                            Image(systemName: "gearshape")
                            Text("Settings...")
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    PulsingTaskDot(color: taskColor, isPulsing: isRunning)
                    
                    Image(systemName: appState.currentHUDIcon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.85))
                        .symbolEffect(.bounce, value: task?.id)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(Capsule().fill(Color.primary.opacity(0.06)))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            
            // Task Title + Monospaced Stopwatch
            VStack(alignment: .leading, spacing: 1) {
                Text(appState.currentHUDTitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(TimeFormatter.formatStopwatch(appState.engine.elapsedTime, includeTenths: true))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: appState.engine.elapsedTime))
                    .foregroundColor(isRunning ? .primary : .secondary)
            }
            .frame(minWidth: 75, alignment: .leading)
            
            Spacer(minLength: 4)
            
            // Primary Play/Pause Button
            Button {
                appState.toggleTimer()
            } label: {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .symbolEffect(.bounce, value: isRunning)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(isRunning ? Color.orange : AppleTheme.actionBlue))
            }
            .buttonStyle(BouncyButtonStyle())
            
            // Finish / Save Session Button
            if viewState.isHovered || appState.engine.state != .idle {
                Button {
                    appState.stopAndSaveSession()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.primary.opacity(0.85))
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(BouncyButtonStyle())
                .transition(.scale.combined(with: .opacity))
                .help("Finish Session")
            }
            
            // Snap to Notch shortcut button
            if viewState.isHovered {
                Button {
                    OverlayWindowController.shared.snapToAnchor(.notchTopCenter, appState: appState)
                } label: {
                    Image(systemName: "iphone.and.arrow.forward")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(BouncyButtonStyle())
                .transition(.scale.combined(with: .opacity))
                .help("Snap to MacBook Notch")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 3)
        .onHover { hovering in
            withAnimation(AppleTheme.springHover) {
                self.viewState.isHovered = hovering
            }
        }
        .frame(height: 44)
    }
    
    // MARK: - Vertical Edge-Docked Minimal Pill View (Left & Right Screen Edges)
    
    private var verticalEdgePillView: some View {
        let task = appState.activeTask
        let taskColor = task?.color ?? AppleTheme.actionBlue
        let isRunning = appState.engine.state == .running
        let verticalParts = TimeFormatter.formatVerticalComponents(appState.engine.elapsedTime)
        
        return VStack(spacing: 6) {
            // Top: Pulsing Color Dot
            PulsingTaskDot(color: taskColor, isPulsing: isRunning)
                .padding(.top, 4)
            
            // Middle: Category or App Icon
            Menu {
                Section("Active Task") {
                    ForEach(appState.storage.data.tasks) { t in
                        Button {
                            appState.selectTask(t)
                        } label: {
                            HStack {
                                Image(systemName: t.iconName)
                                Text(t.title)
                            }
                        }
                    }
                }
                
                Section("Snap to Screen Edge") {
                    ForEach(ScreenAnchor.allCases) { anchor in
                        Button {
                            OverlayWindowController.shared.snapToAnchor(anchor, appState: appState)
                        } label: {
                            HStack {
                                Image(systemName: anchor.iconName)
                                Text(anchor.rawValue)
                            }
                        }
                    }
                }
                
                Section("Preferences") {
                    Button {
                        appState.openSettings()
                    } label: {
                        HStack {
                            Image(systemName: "gearshape")
                            Text("Settings...")
                        }
                    }
                }
            } label: {
                Image(systemName: appState.currentHUDIcon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.9))
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.primary.opacity(0.06)))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            
            Divider()
                .frame(width: 16)
                .opacity(0.3)
            
            // Vertical Stacked Stopwatch Time
            VStack(spacing: 1.5) {
                ForEach(Array(verticalParts.enumerated()), id: \.offset) { index, part in
                    Text(part)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: appState.engine.elapsedTime))
                        .foregroundColor(isRunning ? .primary : .secondary)
                    
                    if index < verticalParts.count - 1 {
                        Text(":")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
            }
            .padding(.vertical, 2)
            
            Spacer(minLength: 2)
            
            // Quick Action: Play / Pause
            Button {
                appState.toggleTimer()
            } label: {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 9, weight: .bold))
                    .symbolEffect(.bounce, value: isRunning)
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(isRunning ? Color.orange : AppleTheme.actionBlue))
            }
            .buttonStyle(BouncyButtonStyle())
            
            // Finish / Save Session on hover
            if viewState.isHovered || appState.engine.state != .idle {
                Button {
                    appState.stopAndSaveSession()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(.primary.opacity(0.85))
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(BouncyButtonStyle())
                .transition(.scale.combined(with: .opacity))
                .help("Finish Session")
            }
            
            // Snap back to Notch on hover
            if viewState.isHovered {
                Button {
                    OverlayWindowController.shared.snapToAnchor(.notchTopCenter, appState: appState)
                } label: {
                    Image(systemName: "iphone.and.arrow.forward")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(BouncyButtonStyle())
                .transition(.scale.combined(with: .opacity))
                .help("Snap to MacBook Notch")
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .frame(width: 38, height: 172)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 3)
        .onHover { hovering in
            withAnimation(AppleTheme.springHover) {
                self.viewState.isHovered = hovering
            }
        }
    }
}

// MARK: - Micro-Animation Helper Components

@MainActor
private final class PulseState: ObservableObject {
    @Published var pulseScale: CGFloat = 1.0
    @Published var pulseOpacity: Double = 0.8
}

private struct PulsingTaskDot: View {
    let color: Color
    let isPulsing: Bool
    
    @StateObject private var pulseState = PulseState()
    
    var body: some View {
        ZStack {
            if isPulsing {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                    .scaleEffect(pulseState.pulseScale)
                    .opacity(pulseState.pulseOpacity)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 1.6)
                            .repeatForever(autoreverses: true)
                        ) {
                            pulseState.pulseScale = 1.45
                            pulseState.pulseOpacity = 0.0
                        }
                    }
            }
            
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .shadow(color: color.opacity(isPulsing ? 0.9 : 0.0), radius: isPulsing ? 3 : 0)
        }
    }
}

private struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.84), value: configuration.isPressed)
    }
}

private struct BouncyIconButton: View {
    let icon: String
    let size: CGFloat
    var backgroundColor: Color = Color.white.opacity(0.1)
    var foregroundColor: Color = .white.opacity(0.85)
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(isEnabled ? foregroundColor : .white.opacity(0.3))
                .frame(width: size, height: size)
                .background(Circle().fill(backgroundColor))
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(!isEnabled)
    }
}

// MARK: - Native Apple Notch Light Animation

@MainActor
private final class LightAnimState: ObservableObject {
    @Published var rotationAngle: Double = 0
    @Published var isBreathing: Bool = false
    
    func startAnimation() {
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            isBreathing = true
        }
    }
}

private struct NotchLightContourView: View {
    let taskColor: Color
    let isRunning: Bool
    let isExpanded: Bool
    let islandW: CGFloat
    let currentH: CGFloat
    
    @StateObject private var animState = LightAnimState()
    
    var body: some View {
        ZStack {
            // 1. Soft Ambient Under-Glow (Apple Intelligence / Aurora light bloom)
            if isRunning || isExpanded {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: isExpanded ? 24 : 14,
                    bottomTrailingRadius: isExpanded ? 24 : 14,
                    topTrailingRadius: 0,
                    style: .continuous
                )
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            taskColor.opacity(isRunning ? (animState.isBreathing ? 0.8 : 0.4) : 0.25),
                            Color(hex: "#38BDF8")!.opacity(isRunning ? 0.6 : 0.15),
                            Color(hex: "#EC4899")!.opacity(isRunning ? 0.5 : 0.1),
                            AppleTheme.actionBlue.opacity(isRunning ? 0.7 : 0.2),
                            taskColor.opacity(isRunning ? (animState.isBreathing ? 0.8 : 0.4) : 0.25)
                        ]),
                        center: .center,
                        angle: .degrees(animState.rotationAngle)
                    ),
                    lineWidth: isRunning ? 3.5 : 2.0
                )
                .blur(radius: isRunning ? 7 : 3.5)
                .opacity(isRunning ? (animState.isBreathing ? 0.9 : 0.5) : 0.3)
            }
            
            // 2. Precision Laser-Etched Apple Glass Edge Contour
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: isExpanded ? 24 : 14,
                bottomTrailingRadius: isExpanded ? 24 : 14,
                topTrailingRadius: 0,
                style: .continuous
            )
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [
                        taskColor.opacity(isRunning ? 0.95 : 0.35),
                        Color.white.opacity(isRunning ? 0.8 : 0.25),
                        AppleTheme.actionBlue.opacity(isRunning ? 0.9 : 0.3),
                        Color.white.opacity(isRunning ? 0.5 : 0.15),
                        taskColor.opacity(isRunning ? 0.95 : 0.35)
                    ]),
                    center: .center,
                    angle: .degrees(animState.rotationAngle)
                ),
                lineWidth: isRunning ? 1.2 : 0.8
            )
            
            // 3. Subtle Bottom Specular Light Sheen (Apple Dynamic Island active highlight)
            if isRunning {
                VStack {
                    Spacer()
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(animState.isBreathing ? 0.9 : 0.4),
                                    taskColor.opacity(0.9),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: isExpanded ? 220 : 120, height: 1.5)
                        .blur(radius: 0.6)
                        .offset(y: 0.5)
                }
            }
        }
        .frame(width: islandW, height: currentH)
        .onAppear {
            animState.startAnimation()
        }
    }
}

