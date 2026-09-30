import SwiftUI

public struct DashboardWindowView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        NavigationSplitView {
            List(selection: $appState.selectedTab) {
                Label("History", systemImage: "clock.arrow.circlepath")
                    .tag(AppState.DashboardTab.history)
                
                Label("Tasks", systemImage: "tag")
                    .tag(AppState.DashboardTab.tasks)
                
                Label("Settings", systemImage: "gearshape")
                    .tag(AppState.DashboardTab.settings)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
        } detail: {
            switch appState.selectedTab {
            case .history:
                HistoryView(appState: appState)
            case .tasks:
                TaskManagerView(appState: appState)
            case .settings:
                SettingsView(appState: appState)
            }
        }
        .frame(minWidth: 700, minHeight: 480)
        .sheet(isPresented: $appState.isFinishingSession) {
            SessionCompletionSheet(appState: appState)
        }
    }
}
