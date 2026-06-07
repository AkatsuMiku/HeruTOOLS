import SwiftUI
import Combine

@MainActor
final class RAMTabVM: ObservableObject {
    @Published var stats = MemoryStats()
    @Published var isPurging: Bool = false
    @Published var statusMsg: String = ""
    @Published var isError: Bool = false

    func refresh() async {
        stats = await MacCleanerService.shared.getMemoryStats()
    }

    func purgeRAM() async {
        isPurging = true
        statusMsg = ""
        let before = stats.freeGB
        let success = await MacCleanerService.shared.purgeRAM()
        await refresh()
        let after = stats.freeGB
        if success {
            let delta = after - before
            statusMsg = delta > 0.05
                ? String(format: "✓ Freed ~%.1f GB of RAM!", delta)
                : "✓ Purge complete!"
            isError = false
        } else {
            statusMsg = "✗ Purge failed (admin access denied)"
            isError = true
        }
        isPurging = false
    }
}
