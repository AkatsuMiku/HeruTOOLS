import SwiftUI

public struct AestheticGroupBoxStyle: GroupBoxStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            configuration.label
                .font(.system(size: 13, weight: .bold, design: .rounded))
            configuration.content
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor).opacity(0.35))
        )
        // 3D Bevel Lighting Overlay: Catches light at the top edge, casts shadow at the bottom
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.18), .clear, .black.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.2
                )
        )
        // 3D Soft Depth Drop Shadow to float in Z-space
        .shadow(color: Color.black.opacity(0.22), radius: 8, x: 0, y: 4)
    }
}
