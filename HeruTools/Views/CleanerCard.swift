import SwiftUI

// MARK: - CleanerCard (Root View)
struct CleanerCard: View {
    @State private var subTab: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Custom 3D Segmented Picker
            CustomSubTabPicker(selection: $subTab)
                .padding(.bottom, 10)

            switch subTab {
            case 0:
                CleanerMainTab()
                    .transition(.opacity)
            case 1:
                RAMTab()
                    .transition(.opacity)
            case 2:
                LargeFilesTab()
                    .transition(.opacity)
            default:
                EmptyView()
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: subTab)
    }
}
