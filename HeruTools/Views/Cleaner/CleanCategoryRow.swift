import SwiftUI

struct CleanCategoryRow: View {
    let category: CleanCategory
    let isSelected: Bool
    let toggle: () -> Void
    @State private var isHovered = false

    private var accentColor: Color {
        switch category.color {
        case "orange": return .orange
        case "yellow": return .yellow
        case "blue": return .blue
        case "cyan": return .cyan
        case "red": return .red
        case "pink": return .pink
        default: return .gray
        }
    }

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 10) {
                // 3D Glass Icon Capsule
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.25), accentColor.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.white.opacity(0.25), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: accentColor.opacity(0.25), radius: 3, x: 0, y: 1.5)
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(category.name)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(category.sizeBytes > 0 ? category.sizeBytes.formattedFileSize : "Calculating...")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                // Custom 3D Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(isSelected ? accentColor.opacity(0.1) : Color.black.opacity(0.3))
                        .frame(width: 16, height: 16)
                    
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: isSelected
                                    ? [accentColor.opacity(0.6), accentColor.opacity(0.2)]
                                    : [.white.opacity(0.2), .black.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.2
                        )
                        .frame(width: 16, height: 16)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(accentColor)
                            .shadow(color: accentColor.opacity(0.65), radius: 2)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                ZStack {
                    // Deep 3D Shadow layer
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.4))
                        .shadow(color: isSelected ? accentColor.opacity(0.12) : Color.black.opacity(0.25), radius: isSelected ? 6 : 3, y: isSelected ? 3 : 1.5)
                    
                    // Glass Card fill
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isSelected ? 0.08 : 0.04),
                                    Color.white.opacity(isSelected ? 0.02 : 0.01)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Specular 3D Bevel Border
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isSelected ? 0.35 : 0.15),
                                    Color.white.opacity(0.02),
                                    Color.black.opacity(isSelected ? 0.4 : 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(isHovered ? 1.015 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
