import SwiftUI

struct LargeFileRow: View {
    let file: LargeFileItem
    @State private var isHovered = false

    private var ext: String {
        URL(fileURLWithPath: file.path).pathExtension.lowercased()
    }

    private var accentColor: Color {
        switch ext {
        case "mp4", "mov", "mkv", "avi": return .red
        case "dmg", "pkg", "iso": return .orange
        case "zip", "tar", "gz", "rar": return .purple
        case "app": return .cyan
        default: return .blue
        }
    }

    private var iconName: String {
        switch ext {
        case "mp4", "mov", "mkv", "avi": return "film.fill"
        case "dmg", "pkg", "iso": return "externaldrive.fill"
        case "zip", "tar", "gz", "rar": return "archivebox.fill"
        case "app": return "app.fill"
        default: return "doc.fill"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Icon Badge
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.2), accentColor.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: accentColor.opacity(0.2), radius: 2, y: 1)
                    .frame(width: 22, height: 22)
                
                Image(systemName: iconName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(file.name)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(file.path)
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text(file.sizeFormatted)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(file.sizeBytes > 1_073_741_824 ? .red : .orange)
                .shadow(color: (file.sizeBytes > 1_073_741_824 ? Color.red : Color.orange).opacity(0.35), radius: 3)

            Button(action: {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: file.path)])
            }) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            .buttonStyle(.plain)
            .help("Show in Finder")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.04), .white.opacity(0.01)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.12), .clear, .black.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .scaleEffect(isHovered ? 1.012 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
