import Foundation

public enum DiscordPatcher {
    
    private static let settingsPath = NSString(string: "~/Library/Application Support/discord/settings.json").expandingTildeInPath
    private static let settingsBackupPath = NSString(string: "~/Library/Application Support/discord/settings.json.bak").expandingTildeInPath
    
    private static let appPath = "/Applications/Discord.app"
    private static let plistPath = "/Applications/Discord.app/Contents/Info.plist"
    private static let plistBackupPath = "/Applications/Discord.app/Contents/Info.plist.bak"
    private static let wrapperPath = "/Applications/Discord.app/Contents/MacOS/discord_"
    
    // MARK: - Status Checking
    
    public static func checkSettingsStatus() -> String {
        let fm = FileManager.default
        guard fm.fileExists(atPath: settingsPath) else {
            return "Discord Not Found"
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: settingsPath))
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let switches = json["chromiumSwitches"] as? [String: Any]
                let offload = json["offloadAdmControls"] as? Bool
                
                if switches != nil && 
                   switches?["disable-gpu"] != nil && 
                   switches?["disable-gpu-rasterization"] != nil && 
                   offload == true {
                    return "Patched"
                }
            }
            return "Unpatched"
        } catch {
            print("Failed to read discord settings.json: \(error.localizedDescription)")
            return "Corrupted"
        }
    }
    
    public static func checkPlistStatus() -> String {
        let fm = FileManager.default
        guard fm.fileExists(atPath: plistPath) else {
            return "Discord Not Found"
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: plistPath))
            if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                if let exec = plist["CFBundleExecutable"] as? String {
                    if exec == "discord_" {
                        return "Patched"
                    }
                }
            }
            return "Unpatched"
        } catch {
            print("Failed to read Discord Info.plist: \(error.localizedDescription)")
            return "Permissions Needed"
        }
    }
    
    // MARK: - Patching Operations
    
    public static func patchSettings() -> Bool {
        let fm = FileManager.default
        let folder = (settingsPath as NSString).deletingLastPathComponent
        
        do {
            if !fm.fileExists(atPath: folder) {
                try fm.createDirectory(atPath: folder, withIntermediateDirectories: true)
            }
            
            // Backup settings
            if fm.fileExists(atPath: settingsPath) && !fm.fileExists(atPath: settingsBackupPath) {
                try fm.copyItem(atPath: settingsPath, toPath: settingsBackupPath)
            }
            
            var settings: [String: Any] = [:]
            if fm.fileExists(atPath: settingsPath) {
                let data = try Data(contentsOf: URL(fileURLWithPath: settingsPath))
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    settings = json
                }
            }
            
            // Apply GPU stability fixes
            settings["IS_MAXIMIZED"] = settings["IS_MAXIMIZED"] ?? false
            settings["IS_MINIMIZED"] = settings["IS_MINIMIZED"] ?? false
            settings["BACKGROUND_COLOR"] = settings["BACKGROUND_COLOR"] ?? "#000000"
            settings["offloadAdmControls"] = true
            
            // NOTE: Do NOT set USE_NEW_UPDATER=false — it forces the legacy updater
            // which is broken on Discord 0.0.392+ and causes "Downloading update 1 of 1..." infinite loop.
            // Instead we remove it to let the modern updater run normally.
            settings.removeValue(forKey: "USE_NEW_UPDATER")
            
            // GPU flags via Chromium switch map
            settings["chromiumSwitches"] = [
                "disable-gpu": "",
                "disable-gpu-rasterization": ""
            ]
            
            if settings["WINDOW_BOUNDS"] == nil {
                settings["WINDOW_BOUNDS"] = [
                    "x": 0,
                    "y": 63,
                    "width": 940,
                    "height": 919
                ]
            }
            
            let outputData = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted])
            try outputData.write(to: URL(fileURLWithPath: settingsPath), options: [.atomic])
            return true
        } catch {
            print("Settings patch failed: \(error.localizedDescription)")
            return false
        }
    }
    
    public static func patchPlist() async -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: plistPath) else {
            return false
        }
        
        // We write a wrapper bash script in /Applications/Discord.app/Contents/MacOS/discord_
        // This launches the original Discord binary with GPU acceleration flags disabled on startup.
        // It provides absolute stability for AMD systems.
        
        // The wrapper passes through all arguments ("$@") so Discord deep links,
        // protocol handlers and auto-update restarts continue to work correctly.
        let wrapperContent = """
        #!/bin/bash
        exec "/Applications/Discord.app/Contents/MacOS/Discord" --disable-gpu --disable-gpu-rasterization "$@"
        """
        
        // Write wrapper + patch Info.plist via AppleScript with admin privileges.
        // We also reset file ownership so Discord's own updater can still overwrite the bundle.
        let scriptSource = """
        do shell script "mkdir -p /Applications/Discord.app/Contents/MacOS/ && printf '\(wrapperContent.replacingOccurrences(of: "\"", with: "\\\""))' > \(wrapperPath) && chmod +x \(wrapperPath) && chown $(stat -f '%u:%g' /Applications/Discord.app/Contents/MacOS/Discord) \(wrapperPath) && (cp -n \(plistPath) \(plistBackupPath) || true) && plutil -replace CFBundleExecutable -string 'discord_' \(plistPath)" with administrator privileges
        """
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let appleScript = NSAppleScript(source: scriptSource)
                var errorInfo: NSDictionary?
                appleScript?.executeAndReturnError(&errorInfo)
                
                if let err = errorInfo {
                    print("Info.plist elevated patch failed: \(err)")
                    continuation.resume(returning: false)
                } else {
                    print("Successfully applied Info.plist modification and created custom GPU bypass wrapper.")
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    // MARK: - Restore Operations
    
    public static func restoreSettings() -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: settingsBackupPath) else { return false }
        
        do {
            if fm.fileExists(atPath: settingsPath) {
                try fm.removeItem(atPath: settingsPath)
            }
            try fm.copyItem(atPath: settingsBackupPath, toPath: settingsPath)
            return true
        } catch {
            print("Settings restore failed: \(error.localizedDescription)")
            return false
        }
    }
    
    public static func restorePlist() async -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: plistBackupPath) else { return false }
        
        let scriptSource = """
        do shell script "cp \(plistBackupPath) \(plistPath) && rm -f \(wrapperPath) && rm -f \(plistBackupPath)" with administrator privileges
        """
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let appleScript = NSAppleScript(source: scriptSource)
                var errorInfo: NSDictionary?
                appleScript?.executeAndReturnError(&errorInfo)
                
                if let err = errorInfo {
                    print("Info.plist elevated restore failed: \(err)")
                    continuation.resume(returning: false)
                } else {
                    print("Successfully restored original Info.plist configuration.")
                    continuation.resume(returning: true)
                }
            }
        }
    }
}
