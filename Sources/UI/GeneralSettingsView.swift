import SwiftUI

@MainActor
public struct GeneralSettingsView: View {
    @Bindable var appState: AppState
    
    // Local state to keep track of current text fields
    @State private var rememberText = ""
    @State private var displayText = ""
    
    // Validation states
    @State private var isRememberValid = true
    @State private var isDisplayValid = true
    
    @FocusState private var focusedField: Field?
    
    public enum Field {
        case remember
        case display
    }
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with gorgeous layout & gradient icon
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.linearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.purple.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("General Preferences")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Customize your clipboard retention limits and behavior.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Grid-like layout for settings
            VStack(spacing: 16) {
                // Limit: Remember Clippings
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "opticaldisc")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                        .frame(width: 20, height: 20)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remember Clippings")
                            .font(.body)
                            .fontWeight(.medium)
                        Text("Maximum number of items to keep in history.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        TextField("", text: $rememberText)
                            .focused($focusedField, equals: .remember)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: focusedField) { oldValue, newValue in
                                if oldValue == .remember && newValue != .remember {
                                    validateRemember()
                                }
                            }
                            .onSubmit {
                                validateRemember()
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.red, lineWidth: isRememberValid ? 0 : 1.5)
                            )
                        
                        if !isRememberValid {
                            Text("Must be 1–9999")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.red)
                                .transition(.opacity)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                // Limit: Display Clippings
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .frame(width: 20, height: 20)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Display Clippings")
                            .font(.body)
                            .fontWeight(.medium)
                        Text("Number of items shown in the menu bar dropdown.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        TextField("", text: $displayText)
                            .focused($focusedField, equals: .display)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: focusedField) { oldValue, newValue in
                                if oldValue == .display && newValue != .display {
                                    validateDisplay()
                                }
                            }
                            .onSubmit {
                                validateDisplay()
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.red, lineWidth: isDisplayValid ? 0 : 1.5)
                            )
                        
                        if !isDisplayValid {
                            Text("Must be 1–100")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.red)
                                .transition(.opacity)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                Divider()
                
                // Active Options / Checkboxes
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Toggle("", isOn: $appState.isRecordingEnabled)
                            .toggleStyle(.checkbox)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Record clipboard history")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Enable CopyClip monitoring to save new clipboard entries.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        Toggle("", isOn: $appState.isLaunchAtStartupEnabled)
                            .toggleStyle(.checkbox)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start CopyClip at system startup")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Automatically launch the application on system login.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(width: 440)
        .onAppear {
            rememberText = String(appState.maxRememberedClips)
            displayText = String(appState.maxDisplayClips)
        }
        .animation(.easeInOut(duration: 0.15), value: isRememberValid)
        .animation(.easeInOut(duration: 0.15), value: isDisplayValid)
    }
    
    private func validateRemember() {
        if let val = Int(rememberText.trimmingCharacters(in: .whitespacesAndNewlines)), val >= 1 && val <= 9999 {
            isRememberValid = true
            appState.maxRememberedClips = val
        } else {
            isRememberValid = false
        }
    }
    
    private func validateDisplay() {
        if let val = Int(displayText.trimmingCharacters(in: .whitespacesAndNewlines)), val >= 1 && val <= 100 {
            isDisplayValid = true
            appState.maxDisplayClips = val
        } else {
            isDisplayValid = false
        }
    }
}
