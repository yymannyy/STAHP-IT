import SwiftUI

@MainActor
public final class MenuBarViewState: ObservableObject {
    @Published public var newTaskTitle: String = ""
    @Published public var showingNewTaskField: Bool = false
    public init() {}
}

public struct MenuBarView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewState = MenuBarViewState()
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        let task = appState.activeTask
        let taskColor = task?.color ?? AppleTheme.actionBlue
        let isRunning = appState.engine.state == .running
        
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "stopwatch.fill")
                        .foregroundColor(AppleTheme.actionBlue)
                        .font(.system(size: 13, weight: .semibold))
                    Text("STAHP IT!")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(-0.28)
                }
                
                Spacer()
                
                // Toggle Notch / Overlay Mode with fluid capsule
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        appState.toggleOverlay()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: appState.storage.data.overlayMode == .notch ? "iphone.and.arrow.forward" : "pip.fill")
                            .font(.system(size: 10))
                        Text(appState.isOverlayVisible ? (appState.storage.data.overlayMode == .notch ? "Notch On" : "HUD On") : "Overlay Off")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule()
                            .fill(appState.isOverlayVisible ? AppleTheme.actionBlue.opacity(0.12) : Color.primary.opacity(0.06))
                    )
                    .foregroundColor(appState.isOverlayVisible ? AppleTheme.actionBlue : .secondary)
                }
                .buttonStyle(BouncyScaleStyle())
                .help("Toggle Overlay Integration")
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Divider()
            
            // Active Timer Card (Apple System Settings / Control Center style card)
            VStack(spacing: 10) {
                // Task Badge & Running Tag
                HStack(spacing: 6) {
                    Circle()
                        .fill(taskColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: taskColor.opacity(isRunning ? 0.8 : 0.0), radius: isRunning ? 3 : 0)
                    
                    Text(appState.currentHUDTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(appState.engine.state.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(
                            Capsule().fill(isRunning ? Color.green.opacity(0.15) : Color.primary.opacity(0.08))
                        )
                        .foregroundColor(isRunning ? .green : .secondary)
                }
                
                // Monospaced Stopwatch Display with negative letter spacing
                Text(TimeFormatter.formatStopwatch(appState.engine.elapsedTime, includeTenths: true, alwaysIncludeHours: true))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: appState.engine.elapsedTime))
                    .tracking(-0.374)
                    .foregroundColor(isRunning ? .primary : .secondary)
                    .padding(.vertical, 2)
                
                // Primary Action Buttons
                HStack(spacing: 10) {
                    // Reset
                    Button {
                        withAnimation(AppleTheme.springSnappy) {
                            appState.engine.reset()
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.primary.opacity(0.06)))
                            .foregroundColor(appState.engine.elapsedTime > 0 ? .primary : .secondary.opacity(0.5))
                    }
                    .buttonStyle(BouncyScaleStyle())
                    .disabled(appState.engine.elapsedTime == 0)
                    .help("Reset Timer")
                    
                    // Main Play/Pause (Apple Action Blue Capsule)
                    Button {
                        withAnimation(AppleTheme.springBouncy) {
                            appState.toggleTimer()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 12, weight: .bold))
                                .symbolEffect(.bounce, value: isRunning)
                            Text(isRunning ? "Pause" : (appState.engine.elapsedTime > 0 ? "Resume" : "Start"))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(minWidth: 105, minHeight: 32)
                        .background(
                            Capsule()
                                .fill(isRunning ? Color.orange : AppleTheme.actionBlue)
                        )
                    }
                    .buttonStyle(BouncyScaleStyle())
                    
                    // Finish & Save Session
                    Button {
                        withAnimation(AppleTheme.springBouncy) {
                            appState.stopAndSaveSession()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .heavy))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle().fill(appState.engine.elapsedTime > 0 ? Color.green.opacity(0.85) : Color.primary.opacity(0.06))
                            )
                            .foregroundColor(appState.engine.elapsedTime > 0 ? .white : .secondary.opacity(0.5))
                    }
                    .buttonStyle(BouncyScaleStyle())
                    .disabled(appState.engine.elapsedTime == 0)
                    .help("Finish & Save to History")
                }
                
                // Laps preview
                if !appState.engine.laps.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Recent Laps")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Record Lap") {
                                appState.recordLap()
                            }
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppleTheme.actionBlue)
                        }
                        
                        ForEach(appState.engine.laps.prefix(2)) { lap in
                            HStack {
                                Text("Lap \(lap.lapNumber)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(TimeFormatter.formatStopwatch(lap.splitTime))
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                            }
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.04)))
                    .transition(.opacity)
                }
            }
            .padding(14)
            .background(Color.primary.opacity(0.03))
            
            Divider()
            
            // Tasks Section
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Tasks")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            viewState.showingNewTaskField.toggle()
                        }
                    } label: {
                        Image(systemName: viewState.showingNewTaskField ? "chevron.up" : "plus")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppleTheme.actionBlue)
                    }
                    .buttonStyle(.plain)
                }
                
                if viewState.showingNewTaskField {
                    HStack(spacing: 6) {
                        TextField("New Task name...", text: $viewState.newTaskTitle)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))
                            .onSubmit {
                                addNewTask()
                            }
                        
                        Button("Add") {
                            addNewTask()
                        }
                        .buttonStyle(ApplePillButtonStyle(isCompact: true))
                        .disabled(viewState.newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.vertical, 2)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
                
                // Tasks List
                ScrollView {
                    VStack(spacing: 3) {
                        ForEach(appState.storage.data.tasks.prefix(6)) { t in
                            let isSelected = t.id == task?.id
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                    appState.selectTask(t)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(t.color)
                                        .frame(width: 7, height: 7)
                                    
                                    Image(systemName: t.iconName)
                                        .font(.system(size: 11))
                                        .foregroundColor(isSelected ? t.color : .secondary)
                                        .frame(width: 14)
                                    
                                    Text(t.title)
                                        .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                                        .foregroundColor(isSelected ? .primary : .secondary)
                                    
                                    Spacer()
                                    
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(t.color)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(isSelected ? t.color.opacity(0.12) : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 120)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            
            Divider()
            
            // Bottom Action Bar
            HStack(spacing: 12) {
                Button {
                    appState.showingDashboard = true
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.doc.horizontal")
                        Text("Dashboard")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(AppleTheme.actionBlue)
                }
                .buttonStyle(.plain)
                
                Button {
                    appState.openSettings()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open Settings Dialog (⌘,)")
                
                Spacer()
                
                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.02))
        }
        .frame(width: 300)
    }
    
    private func addNewTask() {
        let trimmed = viewState.newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let colors = ["#0071E3", "#10B981", "#EC4899", "#F59E0B", "#6366F1", "#8B5CF6", "#EF4444"]
        let randomColor = colors.randomElement() ?? "#0071E3"
        let newTask = TaskItem(title: trimmed, colorHex: randomColor, iconName: "tag.fill")
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            appState.storage.addTask(newTask)
            appState.selectTask(newTask)
            viewState.newTaskTitle = ""
            viewState.showingNewTaskField = false
        }
    }
}

private struct BouncyScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
    }
}
