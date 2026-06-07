import SwiftUI
import Combine

@MainActor
final class CleanerMainVM: ObservableObject {
    @Published var categories: [CleanCategory] = MacCleanerService.shared.makeDefaultCategories()
    @Published var isScanning: Bool = false
    @Published var isCleaning: Bool = false
    @Published var statusMessage: String = ""
    @Published var statusIsError: Bool = false

    var totalSizeBytes: Int64 { categories.reduce(0) { $0 + $1.sizeBytes } }
    var selectedTotal: Int64 { categories.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeBytes } }
    var totalSizeFormatted: String { totalSizeBytes.formattedFileSize }

    func scan() async {
        isScanning = true
        statusMessage = ""
        var local = categories
        await MacCleanerService.shared.calculateSizes(for: &local)
        categories = local
        isScanning = false
    }

    func clean() async {
        guard !isCleaning else { return }
        isCleaning = true
        statusMessage = ""

        let (cleaned, errors) = await MacCleanerService.shared.cleanCategories(categories)

        if errors.isEmpty {
            statusMessage = "✓ Cleaned \(cleaned.formattedFileSize) of junk!"
            statusIsError = false
        } else {
            statusMessage = "Cleaned \(cleaned.formattedFileSize). \(errors.count) error(s): \(errors.first ?? "")"
            statusIsError = true
        }

        isCleaning = false
        await scan()
    }

    func flushDNS() async {
        statusMessage = "Flushing DNS..."
        statusIsError = false
        let success = await MacCleanerService.shared.flushDNS()
        statusMessage = success ? "✓ DNS cache flushed!" : "✗ DNS flush failed (admin required)"
        statusIsError = !success
    }

    func cleanSimulators() async {
        isCleaning = true
        statusMessage = "Removing unavailable simulators..."
        let result = await MacCleanerService.shared.cleanXcodeSimulators()
        statusMessage = "✓ Simulators cleaned. \(result)"
        isCleaning = false
        await scan()
    }
}
