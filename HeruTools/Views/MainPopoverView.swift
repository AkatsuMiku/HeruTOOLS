import SwiftUI

struct MainPopoverView: View {
    @ObservedObject var state = AppState.shared
    @ObservedObject var dependencyManager = DependencyManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Unified Transparent Header
            HStack(spacing: 8) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("HeruTools")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("Hackintosh AMD Optimizer • Tahoe 26")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    state.checkAllStatuses()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Refresh Statuses")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
            
            Divider()
            
            // Custom Premium 3D Segmented Control (Solves the clipping and unneat corner issues!)
            HStack(spacing: 0) {
                ForEach(0..<5) { index in
                    Button(action: {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.78)) {
                            selectedTab = index
                        }
                    }) {
                        Text(tabTitle(index))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTab == index ? .white : .white.opacity(0.55))
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    if selectedTab == index {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "0A84FF").opacity(0.85), Color(hex: "0A84FF")],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                                            )
                                            .shadow(color: Color(hex: "0A84FF").opacity(0.35), radius: 3, y: 1.5)
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                    
                    // Native-like thin vertical divider between tabs (only show when not selected)
                    if index < 4 && selectedTab != index && selectedTab != index + 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 1, height: 12)
                    }
                }
            }
            .padding(2)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.clear)
            
            Divider()
            
            if !dependencyManager.isInstalled {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Missing Media Engine")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(dependencyManager.isDownloading ? dependencyManager.statusMessage : "RIFE & Compression require FFmpeg core.")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        if dependencyManager.isDownloading {
                            ProgressView(value: dependencyManager.downloadProgress)
                                .progressViewStyle(.linear)
                                .frame(width: 80)
                        } else {
                            Button(action: {
                                Task {
                                    await dependencyManager.downloadDependencies()
                                }
                            }) {
                                Text("Auto Install")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            
            // Active Tab View container (floating cards sit here)
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    switch selectedTab {
                    case 0:
                        DiscordFixCard()
                            .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                    case 1:
                        RifeCard()
                            .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                    case 2:
                        CompressorCard()
                            .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                    case 3:
                        SpicetifyCard()
                            .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                    case 4:
                        CleanerCard()
                            .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .frame(height: 340, alignment: .top)
            .background(Color.clear)
            .animation(.easeInOut(duration: 0.12), value: selectedTab)
            
            Divider()
            
            // Unified Spacious Footer
            HStack {
                Text("v1.0.3")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit Toolbox")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.red.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .background(Color.clear)
        }
        .frame(width: 380, height: 490)
        .preferredColorScheme(.dark)
    }
    
    private func tabTitle(_ index: Int) -> String {
        switch index {
        case 0: return "Fix"
        case 1: return "RIFE"
        case 2: return "Compress"
        case 3: return "Spicetify"
        case 4: return "Clean"
        default: return ""
        }
    }
}
