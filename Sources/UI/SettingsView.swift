import SwiftUI

@MainActor
public struct SettingsView: View {
    let appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        TabView {
            GeneralSettingsView(appState: appState)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag("general")
            
            IgnoredAppsView(appState: appState)
                .tabItem {
                    Label("Ignored Apps", systemImage: "hand.raised")
                }
                .tag("ignored")
            
            ClipsManagementView(appState: appState)
                .tabItem {
                    Label("Clips", systemImage: "square.grid.3x1.folder.badge.plus")
                }
                .tag("clips")
        }
        .frame(width: 520, height: 440)
    }
}
