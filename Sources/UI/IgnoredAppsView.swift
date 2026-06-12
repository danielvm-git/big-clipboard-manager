import SwiftUI
import AppKit

struct RunningAppItem: Identifiable {
    let id: String
    let name: String
    let icon: NSImage?
    var isInactive: Bool = false
}

@MainActor
public struct IgnoredAppsView: View {
    @Bindable var appState: AppState
    @State private var runningApps: [RunningAppItem] = []
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with gorgeous layout & red warning/hand shield icon
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.linearGradient(
                            colors: [Color.red.opacity(0.8), Color.orange.opacity(0.8)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.orange.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ignored Applications")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Prevent CopyClip from saving clipboard history from these apps.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // List of applications
            ScrollView {
                LazyVStack(spacing: 8) {
                    if runningApps.isEmpty {
                        Text("No applications found")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(runningApps) { app in
                            HStack(spacing: 12) {
                                Toggle("", isOn: Binding(
                                    get: { appState.ignoredAppBundleIds.contains(app.id) },
                                    set: { isChecked in
                                        if isChecked {
                                            if !appState.ignoredAppBundleIds.contains(app.id) {
                                                appState.ignoredAppBundleIds.append(app.id)
                                            }
                                        } else {
                                            appState.ignoredAppBundleIds.removeAll { $0 == app.id }
                                        }
                                    }
                                ))
                                .toggleStyle(.checkbox)
                                
                                if let nsImage = app.icon {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                } else {
                                    Image(systemName: "app.badge.fill")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(app.name)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        if app.isInactive {
                                            Text("(not running)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Text(app.id)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color(NSColor.alternatingContentBackgroundColors[0]).opacity(0.4))
                            .cornerRadius(6)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            Divider()
            
            HStack {
                Spacer()
                Button(action: refreshRunningApps) {
                    Label("Refresh List", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .onAppear {
            refreshRunningApps()
        }
    }
    
    private func refreshRunningApps() {
        let activeApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != nil && $0.localizedName != nil }
            .compactMap { app -> RunningAppItem? in
                guard let bundleId = app.bundleIdentifier, let name = app.localizedName else { return nil }
                return RunningAppItem(id: bundleId, name: name, icon: app.icon)
            }
        
        var seenIds = Set<String>()
        var merged: [RunningAppItem] = []
        
        // 1. Add running apps
        for app in activeApps {
            if !seenIds.contains(app.id) {
                seenIds.insert(app.id)
                merged.append(app)
            }
        }
        
        // 2. Add non-running ignored apps
        for bundleId in appState.ignoredAppBundleIds {
            if !seenIds.contains(bundleId) {
                seenIds.insert(bundleId)
                merged.append(RunningAppItem(id: bundleId, name: bundleId, icon: nil, isInactive: true))
            }
        }
        
        self.runningApps = merged.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
}
