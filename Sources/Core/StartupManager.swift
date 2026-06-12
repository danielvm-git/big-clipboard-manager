import Foundation
import ServiceManagement

/// Manager for handling macOS application startup registration via SMAppService.
public final class StartupManager: Sendable {
    public static let shared = StartupManager()
    
    private init() {}
    
    /// Checks if the app is registered to launch at startup.
    @MainActor
    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    
    /// Toggle registration for launching at startup.
    /// - Parameter enabled: True to register, False to unregister.
    @MainActor
    public func setEnabled(_ enabled: Bool) throws {
        let status = SMAppService.mainApp.status
        if enabled {
            if status != .enabled {
                try SMAppService.mainApp.register()
                print("StartupManager: Registered successfully")
            }
        } else {
            if status == .enabled {
                try SMAppService.mainApp.unregister()
                print("StartupManager: Unregistered successfully")
            }
        }
    }
}
