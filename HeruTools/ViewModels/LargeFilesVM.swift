import SwiftUI
import Combine

@MainActor
final class LargeFilesVM: ObservableObject {
    @Published var files: [LargeFileItem] = []
    @Published var isScanning: Bool = false
    @Published var didScan: Bool = false
    @Published var minSizeMB: Int64 = 200

    func scan() async {
        isScanning = true
        files = []
        files = await MacCleanerService.shared.scanLargeFiles(minSizeMB: minSizeMB)
        isScanning = false
        didScan = true
    }
}
