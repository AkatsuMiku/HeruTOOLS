import SwiftUI

struct SpecularTubeOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(0.35),
                        .white.opacity(0.12),
                        .clear,
                        .black.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .blendMode(.overlay)
    }
}
