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
        }
        .frame(width: 440, height: 320)
    }
}
