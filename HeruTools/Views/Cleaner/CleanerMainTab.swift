import SwiftUI

struct CleanerMainTab: View {
    @StateObject private var vm = CleanerMainVM()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {

                // Total junk summary bar (Dashboard Capsule)
                HStack(spacing: 10) {
                    ZStack {
                        // Deep 3D Shadow
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.black.opacity(0.45))
                            .shadow(color: Color(hex: "FF6B35").opacity(0.15), radius: 8, y: 4)
                        
                        // Specular glow fill
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B35").opacity(0.18), Color(hex: "F7C59F").opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Specular Bevel stroke
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color(hex: "F7C59F").opacity(0.35), .clear, Color.black.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                        
                        HStack(spacing: 10) {
                            // Pulse-animated glass orb
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FF6B35").opacity(0.25), Color(hex: "FF453A").opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(color: Color(hex: "FF6B35").opacity(0.3), radius: 4)
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "FF8C5A"), Color(hex: "FF3B30")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .font(.system(size: 14))
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(vm.totalSizeFormatted)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: Color(hex: "FF6B35").opacity(0.3), radius: 4)
                                Text("Junk found")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            if vm.isScanning {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Button(action: {
                                    Task {
                                        await vm.scan()
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.08))
                                            .overlay(
                                                Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                            .frame(width: 24, height: 24)
                                        
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .buttonStyle(.plain)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .frame(height: 50)
                }

                // Category rows
                VStack(spacing: 6) {
                    ForEach(vm.categories.indices, id: \.self) { i in
                        CleanCategoryRow(
                            category: vm.categories[i],
                            isSelected: vm.categories[i].isSelected
                        ) {
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                                vm.categories[i].isSelected.toggle()
                            }
                        }
                    }
                }

                if !vm.statusMessage.isEmpty {
                    Text(vm.statusMessage)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(vm.statusIsError ? .red : .green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                        .shadow(color: (vm.statusIsError ? Color.red : Color.green).opacity(0.2), radius: 2)
                }

                // Action buttons
                HStack(spacing: 8) {
                    Button(action: {
                        Task { await vm.clean() }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: vm.isCleaning ? "hourglass" : "trash.fill")
                            Text(vm.isCleaning ? "Cleaning..." : "Clean Selected")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Physical3DButtonStyle(baseColor: Color(hex: "FF6B35"), isProminent: true))
                    .disabled(vm.isCleaning || vm.isScanning || vm.selectedTotal == 0)

                    Button(action: {
                        Task { await vm.flushDNS() }
                    }) {
                        Label("Flush DNS", systemImage: "network")
                    }
                    .buttonStyle(Physical3DButtonStyle(baseColor: Color(hex: "0A84FF"), isProminent: false))
                    .disabled(vm.isCleaning)
                }
            }
            .padding(.top, 2)
        }
        .onAppear {
            Task { await vm.scan() }
        }
    }
}
