import Foundation
import AppKit

// MARK: - CleanCategory Model
public struct CleanCategory: Identifiable {
    public let id: UUID
    public let name: String
    public let icon: String
    public let color: String
    public let paths: [String]
    public var sizeBytes: Int64
    public var isSelected: Bool

    public init(name: String, icon: String, color: String, paths: [String]) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.paths = paths
        self.sizeBytes = 0
        self.isSelected = true
    }
}

// MARK: - LargeFileItem Model
public struct LargeFileItem: Identifiable {
    public let id: UUID
    public let path: String
    public let sizeBytes: Int64
    public var name: String { URL(fileURLWithPath: path).lastPathComponent }
    public var sizeFormatted: String { ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file) }

    public init(path: String, sizeBytes: Int64) {
        self.id = UUID()
        self.path = path
        self.sizeBytes = sizeBytes
    }
}

// MARK: - MemoryStats Model
public struct MemoryStats {
    public var wiredGB: Double = 0
    public var activeGB: Double = 0
    public var inactiveGB: Double = 0
    public var compressedGB: Double = 0
    public var freeGB: Double = 0
    public var totalGB: Double = 0
    public var usedPercent: Double = 0
    public var swapUsedGB: Double = 0

    public var pressureColor: String {
        if usedPercent < 60 { return "green" }
        else if usedPercent < 80 { return "yellow" }
        else { return "red" }
    }
}

// MARK: - MacCleanerService
public final class MacCleanerService {

    // MARK: Shared instance
    public static let shared = MacCleanerService()
    private init() {}

    // MARK: - Category Definitions
    public func makeDefaultCategories() -> [CleanCategory] {
        let home = NSHomeDirectory()
        return [
            CleanCategory(
                name: "User Cache",
                icon: "archivebox.fill",
                color: "orange",
                paths: ["\(home)/Library/Caches"]
            ),
            CleanCategory(
                name: "User Logs",
                icon: "doc.text.fill",
                color: "yellow",
                paths: ["\(home)/Library/Logs"]
            ),
            CleanCategory(
                name: "Trash",
                icon: "trash.fill",
                color: "red",
                paths: ["\(home)/.Trash"]
            ),
            CleanCategory(
                name: "System Logs",
                icon: "exclamationmark.triangle.fill",
                color: "pink",
                paths: ["/var/log", "/Library/Logs"]
            )
        ]
    }

    // MARK: - Size Calculation
    public func calculateSizes(for categories: inout [CleanCategory]) async {
        for i in categories.indices {
            var total: Int64 = 0
            for path in categories[i].paths {
                total += directorySize(at: path)
            }
            categories[i].sizeBytes = total
        }
    }

    public func directorySize(at path: String) -> Int64 {
        let fm = FileManager.default
        guard fm.fileExists(atPath: path) else { return 0 }
        var size: Int64 = 0
        if let enumerator = fm.enumerator(at: URL(fileURLWithPath: path),
                                           includingPropertiesForKeys: [.fileSizeKey],
                                           options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                if let s = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(s)
                }
            }
        }
        return size
    }

    // MARK: - Clean Selected Categories
    public func cleanCategories(_ categories: [CleanCategory]) async -> (cleaned: Int64, errors: [String]) {
        var cleaned: Int64 = 0
        var errors: [String] = []
        let fm = FileManager.default

        for cat in categories where cat.isSelected {
            for path in cat.paths {
                guard fm.fileExists(atPath: path) else { continue }
                do {
                    let contents = try fm.contentsOfDirectory(atPath: path)
                    for item in contents {
                        let itemURL = URL(fileURLWithPath: path).appendingPathComponent(item)
                        if let attrs = try? fm.attributesOfItem(atPath: itemURL.path),
                           let sz = attrs[.size] as? Int64 {
                            _ = sz // placeholder
                        }
                        // Get size before deleting
                        let beforeSize = directorySize(at: itemURL.path)
                        do {
                            try fm.removeItem(at: itemURL)
                            cleaned += beforeSize
                        } catch {
                            errors.append("\(itemURL.lastPathComponent): \(error.localizedDescription)")
                        }
                    }
                } catch {
                    errors.append("\(path): \(error.localizedDescription)")
                }
            }
        }
        return (cleaned, errors)
    }

    // MARK: - Clean Xcode Simulators
    public func cleanXcodeSimulators() async -> String {
        let result = await runShell("/usr/bin/xcrun", args: ["simctl", "delete", "unavailable"])
        return result.isEmpty ? "Done" : result
    }

    // MARK: - RAM Purge (needs sudo via AppleScript helper)
    public func purgeRAM() async -> Bool {
        // We run 'purge' via osascript do shell script with administrator privileges
        let script = "do shell script \"purge\" with administrator privileges"
        let result = await runAppleScript(script)
        return result != nil
    }

    // MARK: - DNS Flush
    public func flushDNS() async -> Bool {
        let script = "do shell script \"dscacheutil -flushcache; killall -HUP mDNSResponder\" with administrator privileges"
        let result = await runAppleScript(script)
        return result != nil
    }

    // MARK: - Empty Trash
    public func emptyTrash() async -> Bool {
        return await withCheckedContinuation { cont in
            DispatchQueue.main.async {
                NSWorkspace.shared.performSelector(onMainThread: #selector(NSObject.description), with: nil, waitUntilDone: false)
                // Use FileManager to empty trash
                let fm = FileManager.default
                let trashPath = NSHomeDirectory() + "/.Trash"
                do {
                    let contents = try fm.contentsOfDirectory(atPath: trashPath)
                    for item in contents {
                        let url = URL(fileURLWithPath: trashPath + "/" + item)
                        try? fm.removeItem(at: url)
                    }
                    cont.resume(returning: true)
                } catch {
                    cont.resume(returning: false)
                }
            }
        }
    }

    // MARK: - Memory Stats
    public func getMemoryStats() async -> MemoryStats {
        var stats = MemoryStats()

        // Total physical RAM
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        stats.totalGB = Double(totalBytes) / 1_073_741_824

        // Parse vm_stat
        let vmOutput = await runShell("/usr/bin/vm_stat", args: [])
        // Try to determine page size
        var ps: Double = 4096
        if vmOutput.contains("page size of 16384") { ps = 16384 }
        else if vmOutput.contains("page size of 4096") { ps = 4096 }

        func pages(_ key: String) -> Double {
            let lines = vmOutput.components(separatedBy: "\n")
            for line in lines {
                if line.contains(key) {
                    let digits = line.components(separatedBy: CharacterSet.decimalDigits.inverted)
                        .joined()
                    if let v = Double(digits) { return v }
                }
            }
            return 0
        }

        let wiredPages = pages("Pages wired down")
        let activePages = pages("Pages active")
        let inactivePages = pages("Pages inactive")
        let compressedPages = pages("Pages occupied by compressor")
        let freePages = pages("Pages free")

        let toGB: (Double) -> Double = { p in (p * ps) / 1_073_741_824 }
        stats.wiredGB = toGB(wiredPages)
        stats.activeGB = toGB(activePages)
        stats.inactiveGB = toGB(inactivePages)
        stats.compressedGB = toGB(compressedPages)
        stats.freeGB = toGB(freePages)

        let usedGB = stats.wiredGB + stats.activeGB + stats.compressedGB
        stats.usedPercent = min((usedGB / max(stats.totalGB, 1)) * 100, 100)

        // Swap usage
        let swapOutput = await runShell("/usr/sbin/sysctl", args: ["vm.swapusage"])
        // Format: vm.swapusage: total = 0.00M  used = 0.00M  free = 0.00M
        if let usedRange = swapOutput.range(of: "used = "),
           let afterUsed = swapOutput[usedRange.upperBound...].split(separator: " ").first,
           let swapM = Double(afterUsed.replacingOccurrences(of: "M", with: "")) {
            stats.swapUsedGB = swapM / 1024
        }

        return stats
    }

    // MARK: - Large File Scanner
    public func scanLargeFiles(minSizeMB: Int64 = 200, maxResults: Int = 50) async -> [LargeFileItem] {
        let minBytes = minSizeMB * 1024 * 1024
        let searchPaths = [NSHomeDirectory(), "/Applications"]
        return await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                var results: [LargeFileItem] = []
                let fm = FileManager.default
                for root in searchPaths {
                    guard let enumerator = fm.enumerator(
                        at: URL(fileURLWithPath: root),
                        includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                        options: [.skipsHiddenFiles, .skipsPackageDescendants]
                    ) else { continue }
                    for case let url as URL in enumerator {
                        guard let res = try? url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                              res.isDirectory == false,
                              let size = res.fileSize,
                              Int64(size) >= minBytes else { continue }
                        results.append(LargeFileItem(path: url.path, sizeBytes: Int64(size)))
                        if results.count >= maxResults * 2 { break }
                    }
                }
                let sorted = Array(results.sorted { $0.sizeBytes > $1.sizeBytes }.prefix(maxResults))
                cont.resume(returning: sorted)
            }
        }
    }

    // MARK: - Shell Helpers
    @discardableResult
    private func runShell(_ exec: String, args: [String]) async -> String {
        return await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                let proc = Process()
                let pipe = Pipe()
                proc.executableURL = URL(fileURLWithPath: exec)
                proc.arguments = args
                proc.standardOutput = pipe
                proc.standardError = pipe
                do {
                    try proc.run()
                    proc.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    cont.resume(returning: String(data: data, encoding: .utf8) ?? "")
                } catch {
                    cont.resume(returning: "")
                }
            }
        }
    }

    private func runAppleScript(_ source: String) async -> String? {
        return await withCheckedContinuation { cont in
            DispatchQueue.main.async {
                var error: NSDictionary?
                let script = NSAppleScript(source: source)
                let result = script?.executeAndReturnError(&error)
                if let e = error {
                    print("AppleScript error: \(e)")
                    cont.resume(returning: nil)
                } else {
                    cont.resume(returning: result?.stringValue ?? "")
                }
            }
        }
    }
}

// MARK: - Formatting Helper
extension Int64 {
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}
