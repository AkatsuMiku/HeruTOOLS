import Foundation

public enum SpicetifyService {
    
    private static func runCommand(action: String) async -> (Int32, String) {
        let script = PythonRunner.getScriptPath(name: "SpicetifyMgr.py")
        
        // We use an actor or local reference to capture stdout lines safely in a thread-safe manner
        let outputCollector = OutputCollector()
        
        return await withCheckedContinuation { continuation in
            let process = PythonRunner.runPythonScript(
                scriptPath: script, 
                arguments: [action], 
                outputCallback: { line in
                    outputCollector.append(line)
                }, 
                completion: { exitCode in
                    continuation.resume(returning: (exitCode, outputCollector.getOutput()))
                }
            )
            if process == nil {
                continuation.resume(returning: (-1, "Execution failed to start"))
            }
        }
    }
    
    public static func checkStatus() async -> String {
        let (_, output) = await runCommand(action: "status")
        let cleaned = output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleaned.contains("spotify_not_found") {
            return "Spotify Not Found"
        } else if cleaned.contains("installed_no_backup") {
            return "Patched (No Backup)"
        } else if cleaned.contains("installed") {
            return "Installed"
        } else if cleaned.contains("missing") {
            return "Missing"
        }
        return "Missing"
    }
    
    public static func install() async -> Bool {
        let (exitCode, _) = await runCommand(action: "install")
        return exitCode == 0
    }
    
    public static func restore() async -> Bool {
        let (exitCode, _) = await runCommand(action: "restore")
        return exitCode == 0
    }
    
    public static func update() async -> Bool {
        let (exitCode, _) = await runCommand(action: "update")
        return exitCode == 0
    }
    
    public static func backup() async -> Bool {
        let (exitCode, _) = await runCommand(action: "backup")
        return exitCode == 0
    }
}

/// Helper class to coordinate thread-safe stdout collections from background callbacks
private final class OutputCollector: @unchecked Sendable {
    private var outputString = ""
    private let lock = NSLock()
    
    func append(_ line: String) {
        lock.lock()
        defer { lock.unlock() }
        outputString += line + "\n"
    }
    
    func getOutput() -> String {
        lock.lock()
        defer { lock.unlock() }
        return outputString
    }
}
