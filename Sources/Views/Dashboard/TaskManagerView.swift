import SwiftUI

@MainActor
public final class TaskManagerState: ObservableObject {
    @Published public var newTaskTitle: String = ""
    @Published public var selectedColorHex: String = "#0071E3"
    @Published public var selectedIcon: String = "tag.fill"
    @Published public var targetMinutes: String = ""
    @Published public var showingAddForm: Bool = false
    public init() {}
}

public struct TaskManagerView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewState = TaskManagerState()
    
    private let availableColors = [
        "#0071E3", "#10B981", "#EC4899", "#F59E0B",
        "#6366F1", "#8B5CF6", "#EF4444", "#14B8A6",
        "#F97316", "#64748B"
    ]
    
    private let availableIcons = [
        "tag.fill", "brain.head.profile", "chevron.left.forwardslash.chevron.right",
        "paintpalette.fill", "person.2.fill", "doc.text.fill",
        "checklist", "hammer.fill", "laptopcomputer", "book.fill",
        "phone.fill", "envelope.fill", "briefcase.fill", "flame.fill"
    ]
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Task Categories")
                        .font(.system(size: 22, weight: .bold))
                        .tracking(-0.374)
                    Text("Manage tasks and color tags for time tracking")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(AppleTheme.springBouncy) {
                        viewState.showingAddForm.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewState.showingAddForm ? "chevron.up" : "plus")
                        Text(viewState.showingAddForm ? "Cancel" : "New Task")
                    }
                }
                .buttonStyle(ApplePillButtonStyle())
            }
            .padding(18)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Add Task Form (Apple Card style)
            if viewState.showingAddForm {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Create New Task")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        TextField("Task title (e.g., Code Review)", text: $viewState.newTaskTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Target mins (optional)", text: $viewState.targetMinutes)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                    }
                    
                    // Color selection
                    HStack(spacing: 8) {
                        Text("Color:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(availableColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: viewState.selectedColorHex == hex ? 2 : 0)
                                )
                                .scaleEffect(viewState.selectedColorHex == hex ? 1.15 : 1.0)
                                .animation(AppleTheme.springSnappy, value: viewState.selectedColorHex)
                                .shadow(radius: viewState.selectedColorHex == hex ? 2 : 0)
                                .onTapGesture {
                                    withAnimation(AppleTheme.springSnappy) {
                                        viewState.selectedColorHex = hex
                                    }
                                }
                        }
                    }
                    
                    // Icon selection
                    HStack(spacing: 8) {
                        Text("Icon:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Image(systemName: icon)
                                        .font(.system(size: 12))
                                        .frame(width: 26, height: 26)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(viewState.selectedIcon == icon ? Color.primary.opacity(0.15) : Color.primary.opacity(0.04))
                                        )
                                        .scaleEffect(viewState.selectedIcon == icon ? 1.12 : 1.0)
                                        .animation(AppleTheme.springSnappy, value: viewState.selectedIcon)
                                        .foregroundColor(viewState.selectedIcon == icon ? Color(hex: viewState.selectedColorHex) : .secondary)
                                        .onTapGesture {
                                            withAnimation(AppleTheme.springSnappy) {
                                                viewState.selectedIcon = icon
                                            }
                                        }
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Spacer()
                        Button("Create Task") {
                            createTask()
                        }
                        .buttonStyle(ApplePillButtonStyle())
                        .disabled(viewState.newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding(16)
                .background(Color.primary.opacity(0.03))
                
                Divider()
            }
            
            // Task List
            List {
                ForEach(appState.storage.data.tasks) { task in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(task.color)
                            .frame(width: 10, height: 10)
                        
                        Image(systemName: task.iconName)
                            .font(.system(size: 13))
                            .foregroundColor(task.color)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.system(size: 13, weight: .semibold))
                            
                            if let target = task.targetMinutes {
                                Text("Goal: \(target) mins / day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if appState.activeTask?.id == task.id {
                            Text("Active")
                                .font(.caption.bold())
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(task.color.opacity(0.15)))
                                .foregroundColor(task.color)
                        }
                        
                        Button {
                            appState.storage.deleteTask(id: task.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                        .disabled(appState.storage.data.tasks.count <= 1)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.inset)
        }
    }
    
    private func createTask() {
        let trimmed = viewState.newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let target = Int(viewState.targetMinutes)
        let task = TaskItem(
            title: trimmed,
            colorHex: viewState.selectedColorHex,
            iconName: viewState.selectedIcon,
            targetMinutes: target
        )
        
        appState.storage.addTask(task)
        viewState.newTaskTitle = ""
        viewState.targetMinutes = ""
        viewState.showingAddForm = false
    }
}
