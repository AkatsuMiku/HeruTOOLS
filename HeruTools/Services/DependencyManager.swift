import Foundation
import Combine
import SwiftUI

@MainActor
public final class DependencyManager: ObservableObject {
    public static let shared = DependencyManager()
    
    @Published public var isDownloading = false
    @Published public var downloadProgress: Double = 0.0
    @Published public var statusMessage = ""
    @Published public var checkCompleted = false
    @Published public var isInstalled = false
    
    private var downloadTask: URLSessionDownloadTask?
    
    private init() {
        checkDependencyStatus()
    }
    
    public func checkDependencyStatus() {
        let path = getFFmpegPath()
        isInstalled = (path != nil)
        checkCompleted = true
    }
    
    public func getFFmpegPath() -> String? {
        let appSupportBin = getAppSupportBinPath().appending("/ffmpeg")
        let paths = [
            appSupportBin,
            "/usr/local/bin/ffmpeg",
            "/opt/homebrew/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) && FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    public func getFFprobePath() -> String? {
        let appSupportBin = getAppSupportBinPath().appending("/ffprobe")
        let paths = [
            appSupportBin,
            "/usr/local/bin/ffprobe",
            "/opt/homebrew/bin/ffprobe",
            "/usr/bin/ffprobe"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) && FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    public func getAppSupportBinPath() -> String {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let appSupport = paths.first else { return "" }
        let binFolder = appSupport.appendingPathComponent("HeruTools/bin")
        try? FileManager.default.createDirectory(at: binFolder, withIntermediateDirectories: true, attributes: nil)
        return binFolder.path
    }
    
    public func downloadDependencies() async {
        guard !isDownloading else { return }
        
        isDownloading = true
        downloadProgress = 0.0
        statusMessage = "Downloading FFmpeg & FFprobe..."
        
        let ffmpegZipURL = URL(string: "https://evermeet.cx/ffmpeg/get/zip")!
        let ffprobeZipURL = URL(string: "https://evermeet.cx/ffmpeg/get/ffprobe/zip")!
        
        do {
            statusMessage = "Downloading FFmpeg (~45MB)..."
            let ffmpegZip = try await downloadFile(from: ffmpegZipURL) { [weak self] progress in
                Task { @MainActor in
                    self?.downloadProgress = progress * 0.5
                }
            }
            
            statusMessage = "Downloading FFprobe (~25MB)..."
            let ffprobeZip = try await downloadFile(from: ffprobeZipURL) { [weak self] progress in
                Task { @MainActor in
                    self?.downloadProgress = 0.5 + (progress * 0.4)
                }
            }
            
            statusMessage = "Extracting files..."
            let binPath = getAppSupportBinPath()
            
            try extractZip(at: ffmpegZip, to: binPath)
            try extractZip(at: ffprobeZip, to: binPath)
            
            // Set permissions
            chmod(binPath + "/ffmpeg", 0o755)
            chmod(binPath + "/ffprobe", 0o755)
            
            // Cleanup zips
            try? FileManager.default.removeItem(at: ffmpegZip)
            try? FileManager.default.removeItem(at: ffprobeZip)
            
            statusMessage = "✓ Installed successfully!"
            isDownloading = false
            downloadProgress = 1.0
            isInstalled = true
            
            // Re-check AppState status checks if applicable
            AppState.shared.checkAllStatuses()
        } catch {
            statusMessage = "✗ Error: \(error.localizedDescription)"
            isDownloading = false
            downloadProgress = 0.0
            isInstalled = false
        }
    }
    
    private func downloadFile(from url: URL, progressHandler: @escaping (Double) -> Void) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let session = URLSession(configuration: .default)
            let delegate = DownloadDelegate(continuation: continuation, progressHandler: progressHandler)
            let task = session.downloadTask(with: url)
            task.delegate = delegate
            task.resume()
            self.downloadTask = task
        }
    }
    
    private func extractZip(at zipURL: URL, to destinationPath: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", "-o", zipURL.path, "-d", destinationPath]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw NSError(domain: "UnzipError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to unzip package"])
        }
    }
}

// Download delegate to track download progress
private final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let continuation: CheckedContinuation<URL, Error>
    let progressHandler: (Double) -> Void
    var isFinished = false
    
    init(continuation: CheckedContinuation<URL, Error>, progressHandler: @escaping (Double) -> Void) {
        self.continuation = continuation
        self.progressHandler = progressHandler
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard !isFinished else { return }
        isFinished = true
        
        // Copy to temporary location as didFinishDownloadingTo URL is deleted when callback returns
        let tempDir = FileManager.default.temporaryDirectory
        let destination = tempDir.appendingPathComponent(UUID().uuidString + ".zip")
        do {
            try FileManager.default.moveItem(at: location, to: destination)
            continuation.resume(returning: destination)
        } catch {
            continuation.resume(throwing: error)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            progressHandler(progress)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            guard !isFinished else { return }
            isFinished = true
            continuation.resume(throwing: error)
        }
    }
}
