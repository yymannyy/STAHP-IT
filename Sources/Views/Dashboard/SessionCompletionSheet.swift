import SwiftUI

public struct SessionCompletionSheet: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        if let session = appState.pendingSession {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppleTheme.actionBlue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Session Completed")
                            .font(.headline)
                            .tracking(-0.28)
                        Text("Recorded for \(session.taskTitle)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(TimeFormatter.formatHumanDuration(session.duration))
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(Color.primary.opacity(0.08))
                        )
                }
                
                Divider()
                
                // Notes Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Session Notes")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $appState.finishingNotes)
                        .font(.system(size: 13))
                        .frame(height: 80)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                }
                
                // Laps breakdown if recorded
                if !session.laps.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(session.laps.count) Laps Recorded")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(session.laps) { lap in
                                    VStack(alignment: .leading) {
                                        Text("Lap \(lap.lapNumber)")
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(.secondary)
                                        Text(TimeFormatter.formatStopwatch(lap.splitTime))
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.primary.opacity(0.04)))
                                }
                            }
                        }
                    }
                }
                
                // Buttons
                HStack {
                    Button("Discard") {
                        appState.discardPendingSession()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red.opacity(0.8))
                    .font(.system(size: 12, weight: .medium))
                    
                    Spacer()
                    
                    Button("Save Session") {
                        appState.confirmSessionNotes()
                    }
                    .buttonStyle(ApplePillButtonStyle())
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(20)
            .frame(width: 400)
        }
    }
}
