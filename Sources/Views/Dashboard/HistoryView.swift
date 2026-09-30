import SwiftUI
import AppKit

@MainActor
public final class HistoryViewState: ObservableObject {
    @Published public var selectedFilterTaskId: UUID? = nil
    @Published public var copiedMarkdownFeedback: Bool = false
    public init() {}
}

public struct HistoryView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewState = HistoryViewState()
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    private var filteredSessions: [TimeSession] {
        if let filterId = viewState.selectedFilterTaskId {
            return appState.storage.data.sessions.filter { $0.taskId == filterId }
        }
        return appState.storage.data.sessions
    }
    
    private var totalTrackedDuration: TimeInterval {
        filteredSessions.reduce(0) { $0 + $1.duration }
    }
    
    private var todayTrackedDuration: TimeInterval {
        let calendar = Calendar.current
        return appState.storage.data.sessions
            .filter { calendar.isDateInToday($0.startTime) }
            .reduce(0) { $0 + $1.duration }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Stats Summary Grid (Apple Pro Style Cards)
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Tracked",
                    value: TimeFormatter.formatHumanDuration(totalTrackedDuration),
                    icon: "clock.fill",
                    color: AppleTheme.actionBlue
                )
                
                StatCard(
                    title: "Today's Focus",
                    value: TimeFormatter.formatHumanDuration(todayTrackedDuration),
                    icon: "sun.max.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Total Sessions",
                    value: "\(filteredSessions.count)",
                    icon: "number.circle.fill",
                    color: .green
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Filter & Action Toolbar
            HStack {
                // Task Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        FilterChip(
                            title: "All Tasks",
                            isSelected: viewState.selectedFilterTaskId == nil,
                            color: AppleTheme.actionBlue
                        ) {
                            withAnimation(AppleTheme.springSnappy) {
                                viewState.selectedFilterTaskId = nil
                            }
                        }
                        
                        ForEach(appState.storage.data.tasks) { task in
                            FilterChip(
                                title: task.title,
                                isSelected: viewState.selectedFilterTaskId == task.id,
                                color: task.color
                            ) {
                                withAnimation(AppleTheme.springSnappy) {
                                    viewState.selectedFilterTaskId = task.id
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                Spacer(minLength: 12)
                
                // Export Buttons
                HStack(spacing: 8) {
                    Button {
                        copyMarkdownWorklog()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: viewState.copiedMarkdownFeedback ? "checkmark" : "doc.on.doc")
                                .symbolEffect(.bounce, value: viewState.copiedMarkdownFeedback)
                            Text(viewState.copiedMarkdownFeedback ? "Copied!" : "Copy Markdown")
                        }
                    }
                    .buttonStyle(AppleSecondaryPillStyle(isCompact: true))
                    
                    Button {
                        exportCSVFile()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.doc")
                            Text("Export CSV")
                        }
                    }
                    .buttonStyle(AppleSecondaryPillStyle(isCompact: true))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Sessions List
            if filteredSessions.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary.opacity(0.35))
                    Text("No sessions recorded yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Start the stopwatch from the MacBook Notch (⌥ ⇧ N) or Menu Bar.")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    let grouped = Dictionary(grouping: filteredSessions) { session in
                        Calendar.current.startOfDay(for: session.startTime)
                    }.sorted { $0.key > $1.key }
                    
                    ForEach(grouped, id: \.key) { day, sessions in
                        Section(header: SectionHeaderView(day: day, sessions: sessions)) {
                            ForEach(sessions) { session in
                                SessionRowView(session: session) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        appState.storage.deleteSession(id: session.id)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
    }
    
    private func copyMarkdownWorklog() {
        let md = appState.storage.exportToMarkdown()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(md, forType: .string)
        
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            viewState.copiedMarkdownFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.viewState.copiedMarkdownFeedback = false
            }
        }
    }
    
    private func exportCSVFile() {
        let csv = appState.storage.exportToCSV()
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "stahp-it-sessions-\(Date().formatted(date: .numeric, time: .omitted)).csv"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(Circle().fill(color.opacity(0.12)))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                )
        )
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 11)
                .padding(.vertical, 4.5)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.16) : Color.primary.opacity(0.04))
                )
                .foregroundColor(isSelected ? color : .secondary)
        }
        .buttonStyle(.plain)
    }
}

private struct SectionHeaderView: View {
    let day: Date
    let sessions: [TimeSession]
    
    var body: some View {
        let dayTotal = sessions.reduce(0) { $0 + $1.duration }
        HStack {
            Text(TimeFormatter.formatDayHeader(day))
                .font(.subheadline.bold())
            Spacer()
            Text("Day Total: \(TimeFormatter.formatHumanDuration(dayTotal))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct SessionRowView: View {
    let session: TimeSession
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: session.taskColorHex) ?? AppleTheme.actionBlue)
                .frame(width: 9, height: 9)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(session.taskTitle)
                        .font(.system(size: 13, weight: .semibold))
                    
                    Spacer()
                    
                    Text(TimeFormatter.formatHumanDuration(session.duration))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                }
                
                HStack(spacing: 8) {
                    Text("\(DateFormatter.localizedString(from: session.startTime, dateStyle: .none, timeStyle: .short)) - \(DateFormatter.localizedString(from: session.endTime, dateStyle: .none, timeStyle: .short))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !session.notes.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(session.notes)
                            .font(.caption)
                            .foregroundColor(.primary.opacity(0.85))
                            .lineLimit(1)
                    }
                    
                    if !session.laps.isEmpty {
                        Text("• \(session.laps.count) laps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.45))
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.primary.opacity(0.04)))
            }
            .buttonStyle(.plain)
            .help("Delete session")
        }
        .padding(.vertical, 4)
    }
}
