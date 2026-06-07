import Foundation

public enum PythonRunner {
    
    /// Finds the absolute path to a python script bundled within the app
    public static func getScriptPath(name: String) -> String {
        if let path = Bundle.main.path(forResource: name, ofType: nil, inDirectory: "python") {
            return path
        }
        // Fallback for debug/development outside bundle
        let baseDir = "/Users/herucute/Desktop/MY PROJECT/HERUTOOLS/HeruTools/Resources/python"
        return "\(baseDir)/\(name)"
    }
    
    /// Resolves the python executable binary path in macOS
    private static func findPythonBinary() -> String {
        let options = [
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python3",
            "python3"
        ]
        
        let fm = FileManager.default
        for path in options {
            if fm.fileExists(atPath: path) {
                return path
            }
        }
        return "/usr/bin/python3" // Default fallback
    }
    
    /// Asynchronously runs a Python script, calling outputCallback with stdout lines, and completionCallback upon completion
    public static func runPythonScript(
        scriptPath: String,
        arguments: [String],
        outputCallback: @escaping (String) -> Void,
        completion: @escaping (Int32) -> Void
    ) -> Process? {
        let process = Process()
        let pythonBin = findPythonBinary()
        
        process.executableURL = URL(fileURLWithPath: pythonBin)
        process.arguments = [scriptPath] + arguments
        
        let outPipe = Pipe()
        let errPipe = Pipe()
        
        process.standardOutput = outPipe
        process.standardError = errPipe
        
        // Handle background reading of stdout
        let outHandle = outPipe.fileHandleForReading
        outHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty { return }
            if let line = String(data: data, encoding: .utf8) {
                // Split buffer by newline to process complete status ticks
                let lines = line.components(separatedBy: .newlines)
                for l in lines {
                    let trimmed = l.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        outputCallback(trimmed)
                    }
                }
            }
        }
        
        // Handle background reading of stderr
        let errHandle = errPipe.fileHandleForReading
        errHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty { return }
            if let line = String(data: data, encoding: .utf8) {
                print("[Python Error] \(line.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }
        
        process.terminationHandler = { proc in
            // Clear readability handlers to close pipes
            outPipe.fileHandleForReading.readabilityHandler = nil
            errPipe.fileHandleForReading.readabilityHandler = nil
            completion(proc.terminationStatus)
        }
        
        do {
            try process.run()
            return process
        } catch {
            print("Failed to start python process: \(error.localizedDescription)")
            completion(-1)
            return nil
        }
    }
}
