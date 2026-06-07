import SwiftUI

struct Physical3DButtonStyle: ButtonStyle {
    var baseColor: Color
    var isProminent: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .background(
                ZStack {
                    if isProminent {
                        // Dark bottom extrusion layer
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(baseColor)
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.black.opacity(0.35)))
                            .offset(y: configuration.isPressed ? 0 : 2)
                        
                        // Top shiny gel cap
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [baseColor.opacity(0.4), baseColor],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [.white.opacity(0.4), .white.opacity(0.1), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .offset(y: configuration.isPressed ? 2 : 0)
                            .shadow(color: baseColor.opacity(0.35), radius: configuration.isPressed ? 1 : 5, y: configuration.isPressed ? 0.5 : 2)
                    } else {
                        // Glass physical tab button
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.black.opacity(0.45))
                            .offset(y: configuration.isPressed ? 0 : 1.5)
                        
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [.white.opacity(0.18), .clear, .black.opacity(0.35)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .offset(y: configuration.isPressed ? 1.5 : 0)
                            .shadow(color: .black.opacity(0.25), radius: configuration.isPressed ? 1 : 3, y: configuration.isPressed ? 0.5 : 1.5)
                    }
                }
            )
            .animation(.spring(response: 0.15, dampingFraction: 0.65), value: configuration.isPressed)
    }
}
