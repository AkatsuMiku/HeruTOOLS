import SwiftUI

struct RAMTab: View {
    @StateObject private var vm = RAMTabVM()

    var body: some View {
        VStack(spacing: 10) {
            // Memory liquid neon tube & legend
            VStack(spacing: 8) {
                ZStack {
                    // Tube Outer 3D Mold Container
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.black.opacity(0.5))
                        .shadow(color: .black.opacity(0.4), radius: 3, y: 1.5)
                        .frame(height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )

                    // The Neon Fills
                    GeometryReader { geo in
                        HStack(spacing: 1.5) {
                            // Wired (red-ish neon)
                            let wiredW = geo.size.width * CGFloat(vm.stats.wiredGB / max(vm.stats.totalGB, 1))
                            if wiredW > 2 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FF453A"), Color(hex: "FF6961")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: max(wiredW - 1.5, 0))
                                    .shadow(color: Color(hex: "FF453A").opacity(0.4), radius: 4)
                            }

                            // Active (blue neon)
                            let activeW = geo.size.width * CGFloat(vm.stats.activeGB / max(vm.stats.totalGB, 1))
                            if activeW > 2 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "0A84FF"), Color(hex: "64D2FF")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: max(activeW - 1.5, 0))
                                    .shadow(color: Color(hex: "0A84FF").opacity(0.4), radius: 4)
                            }

                            // Compressed (purple neon)
                            let compW = geo.size.width * CGFloat(vm.stats.compressedGB / max(vm.stats.totalGB, 1))
                            if compW > 2 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "BF5AF2"), Color(hex: "E57CFF")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: max(compW - 1.5, 0))
                                    .shadow(color: Color(hex: "BF5AF2").opacity(0.4), radius: 4)
                            }

                            // Inactive (silver white neon)
                            let inactW = geo.size.width * CGFloat(vm.stats.inactiveGB / max(vm.stats.totalGB, 1))
                            if inactW > 2 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.35), Color.white.opacity(0.15)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: max(inactW - 1.5, 0))
                            }

                            Spacer(minLength: 0)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .frame(height: 20)
                    .padding(.horizontal, 1)

                    // Glass reflection overlay
                    SpecularTubeOverlay()
                        .frame(height: 22)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Legend
                HStack(spacing: 8) {
                    legendDot(color: Color(hex: "FF453A"), label: "Wired", value: vm.stats.wiredGB)
                    legendDot(color: Color(hex: "0A84FF"), label: "Active", value: vm.stats.activeGB)
                    legendDot(color: Color(hex: "BF5AF2"), label: "Compressed", value: vm.stats.compressedGB)
                    legendDot(color: .white.opacity(0.4), label: "Inactive", value: vm.stats.inactiveGB)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                    
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.04), .white.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.15), .clear, .black.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )

            // Stats grid
            HStack(spacing: 8) {
                statBox(label: "Free", value: String(format: "%.1f GB", vm.stats.freeGB), accent: Color(hex: "30D158"), glowColor: Color(hex: "30D158").opacity(0.2))
                statBox(label: "Total", value: String(format: "%.0f GB", vm.stats.totalGB), accent: .white, glowColor: .white.opacity(0.08))
                statBox(label: "Swap Used", value: String(format: "%.2f GB", vm.stats.swapUsedGB), accent: Color(hex: "FF9F0A"), glowColor: Color(hex: "FF9F0A").opacity(0.2))
            }

            // Pressure indicator
            HStack(spacing: 6) {
                PulsingPressureDot(color: pressureColor)
                Text("Memory Pressure: \(Int(vm.stats.usedPercent))% Used")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(pressureColor)
                    .shadow(color: pressureColor.opacity(0.25), radius: 3)
                Spacer()
            }
            .padding(.horizontal, 4)

            if !vm.statusMsg.isEmpty {
                Text(vm.statusMsg)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(vm.isError ? .red : .green)
                    .shadow(color: (vm.isError ? Color.red : Color.green).opacity(0.2), radius: 2)
            }

            // Buttons
            HStack(spacing: 8) {
                Button(action: { Task { await vm.purgeRAM() } }) {
                    HStack(spacing: 5) {
                        Image(systemName: "memorychip")
                        Text(vm.isPurging ? "Purging..." : "Free RAM")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(Physical3DButtonStyle(baseColor: Color(hex: "BF5AF2"), isProminent: true))
                .disabled(vm.isPurging)

                Button(action: { Task { await vm.refresh() } }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .frame(width: 26, height: 26)
                        
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .buttonStyle(.plain)
                .disabled(vm.isPurging)
            }

            Text("Frees inactive memory using macOS purge command (requires admin)")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .onAppear {
            Task { await vm.refresh() }
        }
    }

    private var pressureColor: Color {
        switch vm.stats.pressureColor {
        case "green": return Color(hex: "30D158")
        case "yellow": return Color(hex: "FF9F0A")
        default: return Color(hex: "FF453A")
        }
    }

    @ViewBuilder
    private func legendDot(color: Color, label: String, value: Double) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.5), radius: 2)
            Text("\(label) \(String(format: "%.1f", value))G")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    @ViewBuilder
    private func statBox(label: String, value: String, accent: Color, glowColor: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(accent)
                .shadow(color: glowColor, radius: 4)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1.5)
                
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.04), .white.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .clear, .black.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
        )
    }
}
