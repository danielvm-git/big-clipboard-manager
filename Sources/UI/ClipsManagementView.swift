import SwiftUI
import AppKit

@MainActor
public struct ClipsManagementView: View {
    @Bindable var appState: AppState
    @State private var searchQuery = ""
    @State private var selectedClipId: UUID?
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    var filteredClips: [Clip] {
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return appState.clips
        } else {
            return appState.clips.filter {
                $0.text.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with gorgeous layout & purple database icon
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.linearGradient(
                            colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.pink.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "square.grid.3x1.folder.badge.plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clips Management")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Search, inspect, and remove stored clippings from history.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clips...", text: $searchQuery)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            
            // Clips List
            VStack {
                if filteredClips.isEmpty {
                    VStack {
                        Spacer()
                        Text("No Match Found")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(selection: $selectedClipId) {
                        ForEach(filteredClips) { clip in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatClipText(clip.text))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Text(clip.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .tag(clip.id)
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .frame(maxHeight: .infinity)
            .border(Color.secondary.opacity(0.2), width: 1)
            
            Divider()
            
            // Bottom controls
            HStack {
                Toggle("Confirm before deleting", isOn: $appState.confirmBeforeDeleting)
                    .toggleStyle(.checkbox)
                
                Spacer()
                
                Button(role: .destructive, action: deleteSelectedClip) {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(selectedClipId == nil)
            }
        }
        .padding(24)
    }
    
    private func deleteSelectedClip() {
        guard let id = selectedClipId,
              let clip = appState.clips.first(where: { $0.id == id }) else { return }
        
        if appState.confirmBeforeDeleting {
            let alert = NSAlert()
            alert.messageText = "Confirm Deletion"
            alert.informativeText = "Are you sure you want to delete this clipping?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Delete")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                appState.deleteClip(clip)
                selectedClipId = nil
                JSONLogger.shared.info("ClipsManagementView: Deleted clip with confirmation", metadata: ["clipId": clip.id.uuidString])
            }
        } else {
            appState.deleteClip(clip)
            selectedClipId = nil
            JSONLogger.shared.info("ClipsManagementView: Deleted clip immediately", metadata: ["clipId": clip.id.uuidString])
        }
    }
    
    private func formatClipText(_ text: String) -> String {
        let singleLine = text
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if singleLine.count > 60 {
            return String(singleLine.prefix(60)) + "..."
        }
        return singleLine
    }
}
