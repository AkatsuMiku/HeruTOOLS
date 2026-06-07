import SwiftUI

struct CustomSubTabPicker: View {
    @Binding var selection: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                        selection = index
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: iconFor(index))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(selection == index ? .white : .white.opacity(0.45))
                        Text(titleFor(index))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(selection == index ? .white : .white.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        ZStack {
                            if selection == index {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.12),
                                                Color.white.opacity(0.02)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.28), .clear, .black.opacity(0.35)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(color: Color.black.opacity(0.4), radius: 2, y: 1)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }
    
    private func titleFor(_ index: Int) -> String {
        switch index {
        case 0: return "Clean"
        case 1: return "RAM"
        case 2: return "Big Files"
        default: return ""
        }
    }
    
    private func iconFor(_ index: Int) -> String {
        switch index {
        case 0: return "sparkles"
        case 1: return "memorychip"
        case 2: return "doc.badge.gearshape"
        default: return ""
        }
    }
}
