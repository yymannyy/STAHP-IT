import SwiftUI
import AppKit

public enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case hud = "HUD & Notch"
    case categories = "Categories"
    case appTracking = "App Tracking"
    case timer = "Stopwatch"
    case shortcuts = "Shortcuts"
    case data = "Data & Backup"
    case about = "About"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .general: return "gearshape.fill"
        case .hud: return "iphone.and.arrow.forward"
        case .categories: return "tag.fill"
        case .appTracking: return "app.badge.checkmark"
        case .timer: return "stopwatch.fill"
        case .shortcuts: return "keyboard.fill"
        case .data: return "externaldrive.fill"
        case .about: return "info.circle.fill"
        }
    }
}

@MainActor
public final class SettingsDialogViewState: ObservableObject {
    @Published public var selectedTab: SettingsTab
    
    public init(initialTab: SettingsTab = .general) {
        self.selectedTab = initialTab
    }
}

@MainActor
public final class CategorySettingsViewState: ObservableObject {
    @Published public var showingCreateCard: Bool = false
    @Published public var editingTaskId: UUID? = nil
    
    // Form fields
    @Published public var title: String = ""
    @Published public var selectedColorHex: String = "#0071E3"
    @Published public var selectedIcon: String = "tag.fill"
    @Published public var targetMinutes: String = ""
    
    public init() {}
    
    public func resetForm() {
        title = ""
        selectedColorHex = "#0071E3"
        selectedIcon = "tag.fill"
        targetMinutes = ""
        showingCreateCard = false
        editingTaskId = nil
    }
    
    public func startEditing(_ task: TaskItem) {
        editingTaskId = task.id
        title = task.title
        selectedColorHex = task.colorHex
        selectedIcon = task.iconName
        targetMinutes = task.targetMinutes.map { "\($0)" } ?? ""
        showingCreateCard = false
    }
}

@MainActor
public final class DataSettingsViewState: ObservableObject {
    @Published public var showingClearAlert: Bool = false
    @Published public var showingResetAlert: Bool = false
    @Published public var exportMessage: String? = nil
    
    public init() {}
}

// MARK: - Native Settings Dialog Box View (Tabbed Modal / Window)
public struct SettingsDialogView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewState: SettingsDialogViewState
    
    public init(appState: AppState, initialTab: SettingsTab = .general) {
        self.appState = appState
        self._viewState = StateObject(wrappedValue: SettingsDialogViewState(initialTab: initialTab))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Modern macOS Settings Header Bar
            HStack(spacing: 8) {
                ForEach(SettingsTab.allCases) { tab in
                    let isSelected = viewState.selectedTab == tab
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            viewState.selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? AppleTheme.actionBlue : .secondary)
                            Text(tab.rawValue)
                                .font(.system(size: 10.5, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? .primary : .secondary)
                        }
                        .frame(minWidth: 65)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isSelected ? AppleTheme.actionBlue.opacity(0.12) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color.primary.opacity(0.03))
            
            Divider()
            
            // Tab Content
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch viewState.selectedTab {
                    case .general:
                        GeneralSettingsSection(appState: appState)
                    case .hud:
                        HUDAndNotchSettingsSection(appState: appState)
                    case .categories:
                        CategoriesSettingsSection(appState: appState)
                    case .appTracking:
                        AppTrackingSettingsSection(appState: appState, viewState: viewState)
                    case .timer:
                        TimerSettingsSection(appState: appState)
                    case .shortcuts:
                        ShortcutsSettingsSection()
                    case .data:
                        DataSettingsSection(appState: appState)
                    case .about:
                        AboutSettingsSection()
                    }
                }
                .padding(24)
            }
        }
        .frame(minWidth: 700, idealWidth: 740, minHeight: 560, idealHeight: 600)
    }
}

// MARK: - Embeddable SettingsView (for Dashboard Split View)
public struct SettingsView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        SettingsDialogView(appState: appState)
    }
}

// MARK: - Settings Sections

// 1. General Settings
private struct GeneralSettingsSection: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingHeader(title: "App Presentation Location", subtitle: "Choose whether STAHP IT! appears exclusively on the Notch HUD, Menu Bar, or both.")
            
            GroupBox {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        ForEach(AppDisplayLocation.allCases) { location in
                            let isSelected = appState.storage.data.appDisplayLocation == location
                            Button {
                                withAnimation(AppleTheme.springSnappy) {
                                    appState.setDisplayLocation(location)
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: location.iconName)
                                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                                        .foregroundColor(isSelected ? AppleTheme.actionBlue : .secondary)
                                    
                                    Text(location.rawValue)
                                        .font(.system(size: 11.5, weight: isSelected ? .semibold : .medium))
                                        .foregroundColor(isSelected ? .primary : .secondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, minHeight: 74)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(isSelected ? AppleTheme.actionBlue.opacity(0.12) : Color.primary.opacity(0.04))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(isSelected ? AppleTheme.actionBlue.opacity(0.6) : Color.clear, lineWidth: 1.5)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Text(
                        appState.storage.data.appDisplayLocation == .notchOnly
                            ? "✨ Showing only on the MacBook Notch / screen edge. Menu Bar icon is hidden."
                            : (appState.storage.data.appDisplayLocation == .menuBarOnly
                                ? "🔝 Showing only in the top macOS Menu Bar. Notch overlay is hidden."
                                : "🔲 Showing simultaneously on both the Notch HUD and top Menu Bar.")
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
                .padding(10)
            }
            
            SettingHeader(title: "App Icon & Alternate Styles", subtitle: "Choose your preferred dock and system icon badge style.")
            
            GroupBox {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        ForEach(AppIconChoice.allCases) { iconChoice in
                            let isSelected = appState.storage.data.selectedAppIcon == iconChoice
                            Button {
                                withAnimation(AppleTheme.springSnappy) {
                                    appState.setAppIcon(iconChoice)
                                }
                            } label: {
                                AppIconThumbnailView(choice: iconChoice, isSelected: isSelected)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Text("💡 Selected icon immediately updates the macOS Dock, App Switcher (⌘Tab), and system instances.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                }
                .padding(10)
            }
            
            SettingHeader(title: "General Preferences", subtitle: "Configure launch, menu bar display, and session completion workflow.")
            
            GroupBox {
                VStack(spacing: 14) {
                    ToggleRow(
                        title: "Launch at Login",
                        subtitle: "Start STAHP IT! silently in the background when your Mac starts up",
                        isOn: $appState.storage.data.launchAtLogin
                    )
                    
                    Divider()
                    
                    ToggleRow(
                        title: "Prompt for Session Notes",
                        subtitle: "Show quick note-taking dialog immediately upon finishing a session",
                        isOn: $appState.storage.data.promptSessionNotesOnFinish
                    )
                    
                    Divider()
                    
                    ToggleRow(
                        title: "Auto-Pause on System Sleep",
                        subtitle: "Automatically pause active stopwatch when MacBook lid closes or system sleeps",
                        isOn: $appState.storage.data.autoPauseOnSleep
                    )
                }
                .padding(8)
            }
            
            SettingHeader(title: "Menu Bar Presentation", subtitle: "Customize the status item appearance in your macOS menu bar.")
            
            GroupBox {
                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Menu Bar Item Style")
                                .font(.system(size: 13, weight: .medium))
                            Text("Choose what appears in your Mac top menu bar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $appState.storage.data.menuBarDisplayMode) {
                            ForEach(MenuBarDisplayMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 190)
                    }
                    
                    Divider()
                    
                    ToggleRow(
                        title: "Flash Menu Bar Icon When Active",
                        subtitle: "Gently pulse the menu bar stopwatch icon while a session is running",
                        isOn: $appState.storage.data.flashMenuBarRunning
                    )
                }
                .padding(8)
            }
        }
    }
}

// MARK: - App Icon Visual Preview Thumbnail
private struct AppIconThumbnailView: View {
    let choice: AppIconChoice
    let isSelected: Bool
    
    private var iconImage: NSImage? {
        let nsName = (choice.rawValue as NSString).deletingPathExtension
        let nsExt = (choice.rawValue as NSString).pathExtension
        if let url = Bundle.main.url(forResource: nsName, withExtension: nsExt),
           let img = NSImage(contentsOf: url) {
            return img
        }
        if let resPath = Bundle.main.resourcePath {
            let path = (resPath as NSString).appendingPathComponent(choice.rawValue)
            if let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return NSImage(contentsOfFile: choice.rawValue)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
                
                if let img = iconImage {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 36))
                        .foregroundColor(AppleTheme.actionBlue)
                }
            }
            .frame(width: 66, height: 66)
            
            VStack(spacing: 2) {
                Text(choice.displayName)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                
                if isSelected {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9.5))
                            .foregroundColor(AppleTheme.actionBlue)
                        Text("Active")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(AppleTheme.actionBlue)
                    }
                } else {
                    Text("Select")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? AppleTheme.actionBlue.opacity(0.12) : Color.primary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? AppleTheme.actionBlue.opacity(0.7) : Color.clear, lineWidth: 1.5)
                )
        )
    }
}

// 2. HUD & Notch Settings
private struct HUDAndNotchSettingsSection: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingHeader(title: "Screen Edge Docking & Magnetic Snapping", subtitle: "Select a screen position or drag the overlay anywhere on screen to snap.")
            
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    ToggleRow(
                        title: "Show Overlay HUD on Screen",
                        subtitle: "Display the floating HUD or Dynamic Island on your primary display",
                        isOn: $appState.isOverlayVisible
                    )
                    
                    Divider()
                    
                    Text("Magnetic Screen Position:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    // 3x3 Grid
                    VStack(spacing: 8) {
                        // Top Row
                        HStack(spacing: 8) {
                            AnchorCard(title: "Top Left", icon: "arrow.up.left.square", anchor: .topLeft, current: appState.storage.data.screenAnchor) {
                                OverlayWindowController.shared.snapToAnchor(.topLeft, appState: appState)
                            }
                            AnchorCard(title: "MacBook Notch", icon: "iphone.and.arrow.forward", anchor: .notchTopCenter, current: appState.storage.data.screenAnchor) {
                                OverlayWindowController.shared.snapToAnchor(.notchTopCenter, appState: appState)
                            }
                            AnchorCard(title: "Top Right", icon: "arrow.up.right.square", anchor: .topRight, current: appState.storage.data.screenAnchor) {
                                OverlayWindowController.shared.snapToAnchor(.topRight, appState: appState)
                            }
                        }
                        
                        // Middle Row
                        HStack(spacing: 8) {
                            AnchorCard(title: "Left Edge (Vert)", icon: "sidebar.left", anchor: .leftEdge, current: appState.storage.data.screenAnchor) {
                                OverlayWindowController.shared.snapToAnchor(.leftEdge, appState: appState)
                            }
                            AnchorCard(title: "Free Floating", icon: "hand.draw", anchor: .freeFloat, current: appState.storage.data.screenAnchor) {
                                OverlayWindowController.shared.snapToAnchor(.freeFloat, appState: appState)
                            }
                            AnchorCard(title: "Right Edge (Vert)", icon: "sidebar.right", anchor: .rightEdge, current: appState.storage.data.screenAnchor) {
                                OverlayWindowController.shared.snapToAnchor(.rightEdge, appState: appState)
                            }
                        }
                        
                        // Bottom Row
                        HStack(spacing: 8) {
                            AnchorCard(title: "Bottom Left", icon: "arrow.down.left.square", anchor: .bottomLeft, current: appState.storage.data.screenAnchor) {
                                OverlayWindowController.shared.snapToAnchor(.bottomLeft, appState: appState)
                            }
                            AnchorCard(title: "Bottom Center", icon: "dock.rectangle", anchor: .bottomCenter, current: appState.storage.data.screenAnchor) {
                                OverlayWindowController.shared.snapToAnchor(.bottomCenter, appState: appState)
                            }
                            AnchorCard(title: "Bottom Right", icon: "arrow.down.right.square", anchor: .bottomRight, current: appState.storage.data.screenAnchor) {
                                OverlayWindowController.shared.snapToAnchor(.bottomRight, appState: appState)
                            }
                        }
                    }
                    
                    Text("💡 You can also drag the overlay anywhere on your screen. It will magnetically snap when dropped near any edge or corner.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
            
            SettingHeader(title: "Hardware Notch & Symmetrical Island", subtitle: "Calibrated geometry for MacBook Pro Retina displays.")
            
            GroupBox {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MacBook Pro Hardware Notch")
                                .font(.system(size: 13, weight: .medium))
                            Text(NotchGeometry.hasHardwareNotch() ? "Native 14\" / 16\" hardware notch detected" : "Hardware notch not present — island simulation active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(NotchGeometry.hasHardwareNotch() ? "Active" : "Emulated")
                            .font(.caption.bold())
                            .foregroundColor(NotchGeometry.hasHardwareNotch() ? .green : .orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill((NotchGeometry.hasHardwareNotch() ? Color.green : Color.orange).opacity(0.12)))
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dynamic Wing Symmetry")
                                .font(.system(size: 13, weight: .medium))
                            Text("Left and right wing widths are dynamically equalized with pixel-perfect boundary alignment.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Balanced")
                            .font(.caption.bold())
                            .foregroundColor(AppleTheme.actionBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(AppleTheme.actionBlue.opacity(0.12)))
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Glass Frosted Material")
                                .font(.system(size: 13, weight: .medium))
                            Text("Backdrop blur and vibrancy style")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $appState.storage.data.glassStyle) {
                            ForEach(GlassStyle.allCases) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 190)
                    }
                }
                .padding(8)
            }
        }
    }
}

// 3. Task Categories Settings (Create & Edit Custom Preset Categories)
private struct CategoriesSettingsSection: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewState = CategorySettingsViewState()
    
    private let availableColors = [
        "#0071E3", "#10B981", "#EC4899", "#F59E0B",
        "#6366F1", "#8B5CF6", "#EF4444", "#14B8A6",
        "#F97316", "#64748B", "#38BDF8", "#E11D48"
    ]
    
    private let availableIcons = [
        "tag.fill", "play.rectangle.fill", "film.fill", "chevron.left.forwardslash.chevron.right",
        "brain.head.profile", "paintpalette.fill", "person.2.fill", "doc.text.fill",
        "checklist", "book.fill", "gamecontroller.fill", "music.note",
        "flame.fill", "cup.and.saucer.fill", "sparkles", "star.fill",
        "hammer.fill", "laptopcomputer", "phone.fill", "envelope.fill"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                SettingHeader(
                    title: "Task Categories & Presets",
                    subtitle: "Create custom categories or edit existing presets (name, color tag, icon, target goal)."
                )
                
                Spacer()
                
                Button {
                    withAnimation(AppleTheme.springBouncy) {
                        if viewState.showingCreateCard || viewState.editingTaskId != nil {
                            viewState.resetForm()
                        } else {
                            viewState.showingCreateCard = true
                            viewState.editingTaskId = nil
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: (viewState.showingCreateCard || viewState.editingTaskId != nil) ? "xmark" : "plus")
                        Text((viewState.showingCreateCard || viewState.editingTaskId != nil) ? "Cancel" : "New Category")
                    }
                }
                .buttonStyle(ApplePillButtonStyle(isCompact: true))
            }
            
            // Inline Create / Edit Category Card
            if viewState.showingCreateCard || viewState.editingTaskId != nil {
                let isEditing = viewState.editingTaskId != nil
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(isEditing ? "Edit Category Preset" : "Create Custom Category")
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            if isEditing {
                                Text("Editing Mode")
                                    .font(.caption2.bold())
                                    .foregroundColor(AppleTheme.actionBlue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(AppleTheme.actionBlue.opacity(0.12)))
                            }
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Category Name:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("e.g., YouTube, Stremio, Deep Work", text: $viewState.title)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Daily Target Goal (mins):")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Optional (e.g. 60)", text: $viewState.targetMinutes)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 150)
                            }
                        }
                        
                        // Color palette picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Color Swatch:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                ForEach(availableColors, id: \.self) { hex in
                                    let isSelected = viewState.selectedColorHex.uppercased() == hex.uppercased()
                                    Circle()
                                        .fill(Color(hex: hex) ?? .blue)
                                        .frame(width: 22, height: 22)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: isSelected ? 2.5 : 0)
                                        )
                                        .scaleEffect(isSelected ? 1.18 : 1.0)
                                        .animation(AppleTheme.springSnappy, value: viewState.selectedColorHex)
                                        .shadow(color: isSelected ? (Color(hex: hex) ?? Color.blue).opacity(0.6) : Color.clear, radius: 4)
                                        .onTapGesture {
                                            withAnimation(AppleTheme.springSnappy) {
                                                viewState.selectedColorHex = hex
                                            }
                                        }
                                }
                            }
                        }
                        
                        // SF Symbol icon picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category Icon:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(availableIcons, id: \.self) { icon in
                                        let isSelected = viewState.selectedIcon == icon
                                        Button {
                                            withAnimation(AppleTheme.springSnappy) {
                                                viewState.selectedIcon = icon
                                            }
                                        } label: {
                                            Image(systemName: icon)
                                                .font(.system(size: 13))
                                                .frame(width: 28, height: 28)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                        .fill(isSelected ? Color.primary.opacity(0.15) : Color.primary.opacity(0.04))
                                                )
                                                .scaleEffect(isSelected ? 1.15 : 1.0)
                                                .foregroundColor(isSelected ? Color(hex: viewState.selectedColorHex) : .secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        
                        HStack {
                            Button("Cancel") {
                                withAnimation(AppleTheme.springBouncy) {
                                    viewState.resetForm()
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(isEditing ? "Save Changes" : "Create Category") {
                                saveCategory(isEditing: isEditing)
                            }
                            .buttonStyle(ApplePillButtonStyle(isCompact: true))
                            .disabled(viewState.title.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .padding(12)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            // Categories List
            GroupBox {
                VStack(spacing: 0) {
                    ForEach(Array(appState.storage.data.tasks.enumerated()), id: \.element.id) { index, task in
                        let isSelected = appState.activeTask?.id == task.id
                        
                        HStack(spacing: 12) {
                            Circle()
                                .fill(task.color)
                                .frame(width: 10, height: 10)
                                .shadow(color: task.color.opacity(0.5), radius: 3)
                            
                            Image(systemName: task.iconName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(task.color)
                                .frame(width: 22)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(task.title)
                                        .font(.system(size: 13, weight: .semibold))
                                    
                                    if isSelected {
                                        Text("Active")
                                            .font(.caption2.bold())
                                            .foregroundColor(AppleTheme.actionBlue)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1.5)
                                            .background(Capsule().fill(AppleTheme.actionBlue.opacity(0.12)))
                                    }
                                }
                                
                                if let target = task.targetMinutes {
                                    Text("Goal: \(target) mins / day")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Action: Select Active
                            if !isSelected {
                                Button("Select") {
                                    withAnimation(AppleTheme.springSnappy) {
                                        appState.selectTask(task)
                                    }
                                }
                                .font(.system(size: 11))
                                .buttonStyle(.plain)
                                .foregroundColor(AppleTheme.actionBlue)
                            }
                            
                            // Action: Edit
                            Button {
                                withAnimation(AppleTheme.springBouncy) {
                                    viewState.startEditing(task)
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "pencil")
                                    Text("Edit")
                                }
                                .font(.system(size: 11))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3.5)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))
                            }
                            .buttonStyle(.plain)
                            .help("Edit category details")
                            
                            // Action: Delete
                            Button {
                                withAnimation(AppleTheme.springSnappy) {
                                    appState.storage.deleteTask(id: task.id)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary.opacity(0.6))
                                    .frame(width: 22, height: 22)
                            }
                            .buttonStyle(.plain)
                            .disabled(appState.storage.data.tasks.count <= 1)
                            .help(appState.storage.data.tasks.count <= 1 ? "Cannot delete the only remaining task" : "Delete category")
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                        
                        if index < appState.storage.data.tasks.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(6)
            }
            
            // Bottom Restore Defaults Action
            HStack {
                Spacer()
                Button("Restore Default Preset Categories") {
                    withAnimation(AppleTheme.springBouncy) {
                        appState.storage.restoreDefaultTasks()
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
            }
        }
    }
    
    private func saveCategory(isEditing: Bool) {
        let trimmed = viewState.title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let target = Int(viewState.targetMinutes)
        
        if isEditing, let editingId = viewState.editingTaskId {
            if let index = appState.storage.data.tasks.firstIndex(where: { $0.id == editingId }) {
                var updated = appState.storage.data.tasks[index]
                updated.title = trimmed
                updated.colorHex = viewState.selectedColorHex
                updated.iconName = viewState.selectedIcon
                updated.targetMinutes = target
                
                withAnimation(AppleTheme.springBouncy) {
                    appState.storage.updateTask(updated)
                    viewState.resetForm()
                }
            }
        } else {
            let newTask = TaskItem(
                title: trimmed,
                colorHex: viewState.selectedColorHex,
                iconName: viewState.selectedIcon,
                targetMinutes: target
            )
            
            withAnimation(AppleTheme.springBouncy) {
                appState.storage.addTask(newTask)
                viewState.resetForm()
            }
        }
    }
}

// 4. App Tracking & HUD Display Settings
private struct AppTrackingSettingsSection: View {
    @ObservedObject var appState: AppState
    @ObservedObject var viewState: SettingsDialogViewState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingHeader(title: "Active App Tracking & Labels", subtitle: "Control how task categories and open applications appear on the HUD.")
            
            GroupBox {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("HUD Display Mode")
                            .font(.system(size: 13, weight: .medium))
                        
                        Picker("HUD Mode", selection: $appState.storage.data.hudDisplayMode) {
                            ForEach(HUDDisplayMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: appState.storage.data.hudDisplayMode) { _, _ in
                            appState.storage.save()
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Currently Active macOS App")
                                .font(.system(size: 13, weight: .medium))
                            Text("Detected in real-time via NSWorkspace")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "app.badge.checkmark")
                                .font(.system(size: 11))
                                .foregroundColor(AppleTheme.actionBlue)
                            Text(appState.frontmostAppName.isEmpty ? "Finder / Desktop" : appState.frontmostAppName)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current HUD Title Preview")
                                .font(.system(size: 13, weight: .medium))
                            Text("How the title renders on the left wing of the notch")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(appState.currentHUDTitle)
                            .font(.caption.bold())
                            .foregroundColor(AppleTheme.actionBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AppleTheme.actionBlue.opacity(0.12)))
                    }
                }
                .padding(8)
            }
            
            HStack {
                SettingHeader(title: "Task Categories Quick Access", subtitle: "Configure or customize categories in the Categories tab.")
                Spacer()
                Button("Manage Categories →") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        viewState.selectedTab = .categories
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(AppleTheme.actionBlue)
                .font(.system(size: 12, weight: .medium))
            }
        }
    }
}

// 5. Timer & Audio Settings
private struct TimerSettingsSection: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingHeader(title: "Stopwatch Precision & Formatting", subtitle: "Configure digit resolution and continuous display rules.")
            
            GroupBox {
                VStack(spacing: 14) {
                    ToggleRow(
                        title: "Show Milliseconds / Tenths",
                        subtitle: "Display high-precision tenth-of-a-second digits on the stopwatch",
                        isOn: $appState.storage.data.showMilliseconds
                    )
                    
                    Divider()
                    
                    ToggleRow(
                        title: "Always Include Hours",
                        subtitle: "Format timer as 00:14:32 instead of 14:32 when elapsed time is under one hour",
                        isOn: $appState.storage.data.alwaysShowHours
                    )
                }
                .padding(8)
            }
            
            SettingHeader(title: "Audio Feedback & Sound Effects", subtitle: "Play subtle native macOS system sounds on timer events.")
            
            GroupBox {
                VStack(spacing: 14) {
                    ToggleRow(
                        title: "Enable Sound Effects",
                        subtitle: "Master toggle for all audio alerts and clicks",
                        isOn: $appState.storage.data.soundEnabled
                    )
                    
                    Divider()
                    
                    ToggleRow(
                        title: "Sound on Start & Pause",
                        subtitle: "Play a crisp click sound when toggling stopwatch state",
                        isOn: $appState.storage.data.soundOnStartPause
                    )
                    .disabled(!appState.storage.data.soundEnabled)
                    
                    Divider()
                    
                    ToggleRow(
                        title: "Sound on Session Complete",
                        subtitle: "Play confirmation chime when session is saved to history",
                        isOn: $appState.storage.data.soundOnSessionComplete
                    )
                    .disabled(!appState.storage.data.soundEnabled)
                }
                .padding(8)
            }
            
            SettingHeader(title: "Session Persistence & Auto-Resume", subtitle: "Preserve and automatically restore active stopwatch sessions across app restarts.")
            
            GroupBox {
                VStack(spacing: 14) {
                    ToggleRow(
                        title: "Restore Last Active Session on Launch",
                        subtitle: "Remember stopwatch elapsed time, task category, and laps when quitting STAHP IT!",
                        isOn: $appState.storage.data.restoreSessionOnLaunch
                    )
                    
                    if appState.storage.data.restoreSessionOnLaunch {
                        Divider()
                        
                        ToggleRow(
                            title: "Auto-Resume if Running Before Exit",
                            subtitle: "Automatically resume ticking immediately upon app relaunch if the timer was active",
                            isOn: $appState.storage.data.autoResumeRunningOnLaunch
                        )
                        
                        Divider()
                        
                        ToggleRow(
                            title: "Count Offline Elapsed Time",
                            subtitle: "Add the background time passed while STAHP IT! was closed to the active session",
                            isOn: $appState.storage.data.countOfflineTime
                        )
                    }
                }
                .padding(8)
            }
            
            SettingHeader(title: "Continuous Focus & Idle Reminders", subtitle: "Alert you when a task has been running uninterrupted.")
            
            GroupBox {
                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Continuous Task Alert")
                                .font(.system(size: 13, weight: .medium))
                            Text("Send a notification if the stopwatch has been running non-stop")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $appState.storage.data.idleReminderMinutes) {
                            Text("Disabled").tag(0)
                            Text("After 30 Minutes").tag(30)
                            Text("After 45 Minutes").tag(45)
                            Text("After 1 Hour").tag(60)
                            Text("After 90 Minutes").tag(90)
                            Text("After 2 Hours").tag(120)
                        }
                        .labelsHidden()
                        .frame(width: 160)
                    }
                }
                .padding(8)
            }
        }
    }
}

// 6. Global Keyboard Shortcuts
private struct ShortcutsSettingsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingHeader(title: "Global Keyboard Shortcuts", subtitle: "Control STAHP IT! from anywhere in macOS, even when other applications are focused.")
            
            GroupBox {
                VStack(spacing: 12) {
                    ShortcutRow(title: "Toggle Stopwatch (Start / Pause)", keys: ["⌥", "⇧", "Space"])
                    Divider()
                    ShortcutRow(title: "Toggle Notch & Overlay HUD", keys: ["⌥", "⇧", "N"])
                    Divider()
                    ShortcutRow(title: "Finish & Save Session to History", keys: ["⌥", "⇧", "S"])
                    Divider()
                    ShortcutRow(title: "Open Preferences & Settings Dialog", keys: ["⌘", ","])
                }
                .padding(8)
            }
            
            Text("💡 Carbon hotkeys run at the system level and work seamlessly while inside full-screen apps or games.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// 7. Data & Backup Settings
private struct DataSettingsSection: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewState = DataSettingsViewState()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingHeader(title: "Usage & Tracking Statistics", subtitle: "Overview of your stored sessions and productivity records.")
            
            HStack(spacing: 12) {
                StatCard(title: "Total Sessions", value: "\(appState.storage.data.sessions.count)", icon: "checkmark.circle.fill", color: .green)
                let totalSec = appState.storage.data.sessions.reduce(0.0) { $0 + $1.duration }
                StatCard(title: "Total Tracked", value: TimeFormatter.formatHumanDuration(totalSec), icon: "clock.fill", color: AppleTheme.actionBlue)
                StatCard(title: "Categories", value: "\(appState.storage.data.tasks.count)", icon: "tag.fill", color: .orange)
            }
            
            SettingHeader(title: "Export & Backup", subtitle: "Export your time sessions in common interoperable formats.")
            
            GroupBox {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export to CSV")
                                .font(.system(size: 13, weight: .medium))
                            Text("Spreadsheet-compatible comma-separated file")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Copy CSV") {
                            let csv = appState.storage.exportToCSV()
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(csv, forType: .string)
                            viewState.exportMessage = "CSV copied to clipboard!"
                        }
                        .buttonStyle(ApplePillButtonStyle(isCompact: true))
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export to Markdown Worklog")
                                .font(.system(size: 13, weight: .medium))
                            Text("Formatted tables grouped by day for Notion / Obsidian")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Copy Markdown") {
                            let md = appState.storage.exportToMarkdown()
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(md, forType: .string)
                            viewState.exportMessage = "Markdown worklog copied to clipboard!"
                        }
                        .buttonStyle(ApplePillButtonStyle(isCompact: true))
                    }
                }
                .padding(8)
            }
            
            if let msg = viewState.exportMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(msg)
                        .font(.caption.bold())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.green.opacity(0.12)))
                .transition(.opacity)
            }
            
            SettingHeader(title: "Danger Zone", subtitle: "Manage or erase stored local data.")
            
            GroupBox {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clear All Session History")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                            Text("Permanently deletes all logged stopwatch sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Clear History...") {
                            viewState.showingClearAlert = true
                        }
                        .foregroundColor(.red)
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset Settings to Defaults")
                                .font(.system(size: 13, weight: .medium))
                            Text("Restores all preferences back to factory state")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Reset Settings...") {
                            viewState.showingResetAlert = true
                        }
                    }
                }
                .padding(8)
            }
        }
        .alert("Clear Session History?", isPresented: $viewState.showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All History", role: .destructive) {
                appState.storage.clearAllHistory()
            }
        } message: {
            Text("This will permanently remove all completed session records. This action cannot be undone.")
        }
        .alert("Reset Settings to Defaults?", isPresented: $viewState.showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                appState.storage.resetToDefaults()
            }
        } message: {
            Text("All preferences will be restored to defaults. Your tasks and session history will be preserved.")
        }
    }
}

// 8. About Settings
private struct AboutSettingsSection: View {
    var body: some View {
        VStack(spacing: 16) {
            // App Icon Stop Sign
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.red.opacity(0.4), radius: 10, y: 4)
                
                VStack(spacing: 1) {
                    Text("STAHP")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("IT!")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 10)
            
            VStack(spacing: 4) {
                Text("STAHP IT!")
                    .font(.system(size: 20, weight: .bold))
                    .tracking(-0.4)
                
                Text("Version 1.2 (Build 2026.10)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("A precision task stopwatch designed natively for macOS, featuring MacBook Pro Dynamic Island notch integration, multi-edge magnetic snapping, and real-time active application tracking.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
                .padding(.horizontal, 20)
            
            Divider()
                .frame(maxWidth: 400)
            
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("Native Architecture")
                        .font(.caption2.bold())
                    Text("SwiftUI + AppKit")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 2) {
                    Text("Retina Hardware")
                        .font(.caption2.bold())
                    Text("Apple Silicon & Intel")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 2) {
                    Text("Physics Engine")
                        .font(.caption2.bold())
                    Text("Fluid Spring Dynamics")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Reusable UI Helpers

private struct SettingHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }
}

private struct AnchorCard: View {
    let title: String
    let icon: String
    let anchor: ScreenAnchor
    let current: ScreenAnchor
    let action: () -> Void
    
    var isSelected: Bool {
        anchor == current
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? AppleTheme.actionBlue.opacity(0.15) : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? AppleTheme.actionBlue : Color.clear, lineWidth: 1.5)
            )
            .foregroundColor(isSelected ? AppleTheme.actionBlue : .primary)
        }
        .buttonStyle(.plain)
    }
}

private struct ShortcutRow: View {
    let title: String
    let keys: [String]
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
            Spacer()
            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.primary.opacity(0.08))
                        )
                }
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
                Spacer()
            }
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .lineLimit(1)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}
