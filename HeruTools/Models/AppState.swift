import Foundation
import Combine

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    // Discord Statuses
    @Published public var discordSettingsStatus: String = "Checking..."
    @Published public var discordPlistStatus: String = "Checking..."
    @Published public var autoPatchOnLogin: Bool = false
    
    // Spicetify Statuses
    @Published public var spicetifyStatus: String = "Checking..."
    
    // Asynchronous Tasks
    @Published public var rifeTask = TaskState(name: "RIFE Interpolation")
    @Published public var compressorTask = TaskState(name: "FFmpeg Compression")
    @Published public var discordUpdateTask = TaskState(name: "Discord Fix Updater")
    
    // Operations Cancel Handles
    private var rifeProcess: Process?
    private var compressorProcess: Process?
    private var discordUpdateProcess: Process?
    
    private init() {
        checkAllStatuses()
        autoPatchOnLogin = LoginService.isLoginItemEnabled()
    }
    
    public func checkAllStatuses() {
        checkDiscordStatus()
        checkSpicetifyStatus()
    }
    
    // MARK: - Discord Fix Methods
    
    public func checkDiscordStatus() {
        discordSettingsStatus = DiscordPatcher.checkSettingsStatus()
        discordPlistStatus = DiscordPatcher.checkPlistStatus()
    }
    
    public func patchDiscord() {
        discordSettingsStatus = "Patching..."
        discordPlistStatus = "Patching..."
        
        Task {
            let settingsPatched = DiscordPatcher.patchSettings()
            let plistPatched = await DiscordPatcher.patchPlist()
            
            checkDiscordStatus()
            
            // Auto login logic
            if settingsPatched && plistPatched && autoPatchOnLogin {
                LoginService.registerLoginItem(enabled: true)
            }
        }
    }
    
    /// Re-applies ONLY the Info.plist + discord_ wrapper without touching settings.json.
    /// Use this after Discord auto-updates and removes the wrapper, or before closing Discord.
    public func reApplyWrapper() {
        discordPlistStatus = "Patching..."
        Task {
            let ok = await DiscordPatcher.patchPlist()
            self.discordPlistStatus = ok ? "Patched" : "Permissions Needed"
        }
    }
    
    // MARK: - Discord Fix Update (bypasses stuck internal updater)
    
    /// Downloads and installs the latest Discord via curl, bypassing Discord's
    /// broken internal updater that gets stuck on Hackintosh network setups.
    public func runDiscordFixUpdate() {
        guard !discordUpdateTask.isRunning else { return }
        
        discordUpdateTask.isRunning = true
        discordUpdateTask.progress = 0.0
        discordUpdateTask.status = "Initializing..."
        discordUpdateTask.eta = "--"
        
        let pyScript = PythonRunner.getScriptPath(name: "DiscordUpdater.py")
        
        let proc = PythonRunner.runPythonScript(scriptPath: pyScript, arguments: []) { [weak self] line in
            guard let self = self else { return }
            Task { @MainActor in
                self.parseDiscordUpdateProgress(line)
            }
        } completion: { [weak self] exitCode in
            guard let self = self else { return }
            Task { @MainActor in
                self.discordUpdateTask.isRunning = false
                self.discordUpdateProcess = nil
                if exitCode == 0 {
                    self.discordUpdateTask.progress = 1.0
                    self.discordUpdateTask.status = "Discord updated & GPU patch applied!"
                    // Refresh discord status after update
                    self.checkDiscordStatus()
                } else {
                    self.discordUpdateTask.status = "Failed (code \(exitCode)) — check internet"
                }
            }
        }
        self.discordUpdateProcess = proc
    }
    
    public func cancelDiscordUpdate() {
        discordUpdateProcess?.terminate()
        discordUpdateProcess = nil
        discordUpdateTask.isRunning = false
        discordUpdateTask.status = "Cancelled"
        discordUpdateTask.progress = 0.0
    }
    
    private func parseDiscordUpdateProgress(_ line: String) {
        if line.contains("PROGRESS:") {
            let parts = line.components(separatedBy: "|")
            for part in parts {
                if part.hasPrefix("PROGRESS:") {
                    if let val = Double(part.replacingOccurrences(of: "PROGRESS:", with: "")) {
                        discordUpdateTask.progress = val / 100.0
                    }
                } else if part.hasPrefix("ETA:") {
                    discordUpdateTask.eta = part.replacingOccurrences(of: "ETA:", with: "")
                } else if part.hasPrefix("STATUS:") {
                    discordUpdateTask.status = part.replacingOccurrences(of: "STATUS:", with: "")
                }
            }
        } else if line.contains("SUCCESS:") {
            discordUpdateTask.status = line.replacingOccurrences(of: "SUCCESS:", with: "")
        }
    }
    
    public func restoreDiscord() {
        discordSettingsStatus = "Restoring..."
        discordPlistStatus = "Restoring..."
        
        Task {
            _ = DiscordPatcher.restoreSettings()
            _ = await DiscordPatcher.restorePlist()
            checkDiscordStatus()
        }
    }
    
    public func toggleAutoPatchOnLogin(_ enabled: Bool) {
        autoPatchOnLogin = enabled
        LoginService.registerLoginItem(enabled: enabled)
    }
    
    // MARK: - Spicetify Methods
    
    public func checkSpicetifyStatus() {
        spicetifyStatus = "Checking..."
        Task {
            let status = await SpicetifyService.checkStatus()
            self.spicetifyStatus = status
        }
    }
    
    public func installSpicetify() {
        spicetifyStatus = "Installing..."
        Task {
            let success = await SpicetifyService.install()
            self.spicetifyStatus = success ? "Installed" : "Installation Failed"
            checkSpicetifyStatus()
        }
    }
    
    public func restoreSpicetify() {
        spicetifyStatus = "Restoring..."
        Task {
            _ = await SpicetifyService.restore()
            checkSpicetifyStatus()
        }
    }
    
    public func updateSpicetify() {
        spicetifyStatus = "Updating..."
        Task {
            _ = await SpicetifyService.update()
            checkSpicetifyStatus()
        }
    }
    
    public func backupSpicetify() {
        spicetifyStatus = "Backing up..."
        Task {
            _ = await SpicetifyService.backup()
            checkSpicetifyStatus()
        }
    }
    
    // MARK: - RIFE Frame Interpolation
    
    public func runRife(inputPath: String, fpsFactor: Double, model: String, crf: Int) {
        guard !rifeTask.isRunning else { return }
        
        rifeTask.isRunning = true
        rifeTask.progress = 0.0
        rifeTask.status = "Initializing..."
        rifeTask.eta = "--"
        
        let pyScript = PythonRunner.getScriptPath(name: "RIFEWrapper.py")
        let args = ["--input", inputPath, "--fps_factor", String(fpsFactor), "--model", model, "--crf", String(crf)]
        
        let proc = PythonRunner.runPythonScript(scriptPath: pyScript, arguments: args) { [weak self] line in
            guard let self = self else { return }
            Task { @MainActor in
                self.parseRifeProgress(line)
            }
        } completion: { [weak self] exitCode in
            guard let self = self else { return }
            Task { @MainActor in
                self.rifeTask.isRunning = false
                self.rifeProcess = nil
                if exitCode == 0 {
                    self.rifeTask.progress = 1.0
                    self.rifeTask.status = "Finished: Output saved near original!"
                } else {
                    self.rifeTask.status = "Failed with code \(exitCode)"
                }
            }
        }
        
        self.rifeProcess = proc
    }
    
    public func cancelRife() {
        rifeProcess?.terminate()
        rifeProcess = nil
        rifeTask.isRunning = false
        rifeTask.status = "Cancelled"
        rifeTask.progress = 0.0
    }
    
    private func parseRifeProgress(_ line: String) {
        // Line structure: "PROGRESS:XX|ETA:YYs|STATUS:ZZZ"
        if line.contains("PROGRESS:") {
            let parts = line.components(separatedBy: "|")
            for part in parts {
                if part.hasPrefix("PROGRESS:") {
                    if let val = Double(part.replacingOccurrences(of: "PROGRESS:", with: "")) {
                        rifeTask.progress = val / 100.0
                    }
                } else if part.hasPrefix("ETA:") {
                    rifeTask.eta = part.replacingOccurrences(of: "ETA:", with: "")
                } else if part.hasPrefix("STATUS:") {
                    rifeTask.status = part.replacingOccurrences(of: "STATUS:", with: "")
                }
            }
        } else if line.contains("SUCCESS:") {
            rifeTask.status = line.replacingOccurrences(of: "SUCCESS:", with: "")
        }
    }
    
    // MARK: - FFmpeg Compression
    
    public func runCompressor(inputPath: String, preset: String, codec: String, removeAudio: Bool, targetSize: Double?) {
        guard !compressorTask.isRunning else { return }
        
        compressorTask.isRunning = true
        compressorTask.progress = 0.0
        compressorTask.status = "Initializing..."
        compressorTask.eta = "--"
        compressorTask.outputEstimatedSize = "--"
        
        let pyScript = PythonRunner.getScriptPath(name: "FFmpegWrapper.py")
        var args = ["--input", inputPath, "--preset", preset, "--codec", codec]
        if removeAudio {
            args.append("--remove_audio")
        }
        if let ts = targetSize {
            args.extend(["--target_size", String(ts)])
        }
        
        let proc = PythonRunner.runPythonScript(scriptPath: pyScript, arguments: args) { [weak self] line in
            guard let self = self else { return }
            Task { @MainActor in
                self.parseCompressorProgress(line)
            }
        } completion: { [weak self] exitCode in
            guard let self = self else { return }
            Task { @MainActor in
                self.compressorTask.isRunning = false
                self.compressorProcess = nil
                if exitCode == 0 {
                    self.compressorTask.progress = 1.0
                    self.compressorTask.status = "Finished: Output saved near original!"
                } else {
                    self.compressorTask.status = "Failed with code \(exitCode)"
                }
            }
        }
        
        self.compressorProcess = proc
    }
    
    public func cancelCompressor() {
        compressorProcess?.terminate()
        compressorProcess = nil
        compressorTask.isRunning = false
        compressorTask.status = "Cancelled"
        compressorTask.progress = 0.0
    }
    
    private func parseCompressorProgress(_ line: String) {
        if line.contains("PROGRESS:") {
            let parts = line.components(separatedBy: "|")
            for part in parts {
                if part.hasPrefix("PROGRESS:") {
                    if let val = Double(part.replacingOccurrences(of: "PROGRESS:", with: "")) {
                        compressorTask.progress = val / 100.0
                    }
                } else if part.hasPrefix("ETA:") {
                    compressorTask.eta = part.replacingOccurrences(of: "ETA:", with: "")
                } else if part.hasPrefix("STATUS:") {
                    compressorTask.status = part.replacingOccurrences(of: "STATUS:", with: "")
                }
            }
        } else if line.contains("ESTIMATED_SIZE:") {
            compressorTask.outputEstimatedSize = line.replacingOccurrences(of: "ESTIMATED_SIZE:", with: "")
        } else if line.contains("SUCCESS:") {
            compressorTask.status = line.replacingOccurrences(of: "SUCCESS:", with: "")
        }
    }
    
}

