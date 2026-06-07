import Foundation
import ServiceManagement

public enum LoginService {
    public static func registerLoginItem(enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status != .enabled {
                    try service.register()
                    print("HeruTools registered as a login item successfully.")
                }
            } else {
                if service.status == .enabled {
                    try service.unregister()
                    print("HeruTools unregistered as a login item successfully.")
                }
            }
        } catch {
            print("Failed to update SMAppService status: \(error.localizedDescription)")
        }
    }
    
    public static func isLoginItemEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }
}
