import SwiftUI

struct DiscordFixCard: View {
    @ObservedObject var state = AppState.shared
    
    var body: some View {
        GroupBox(label: 
            HStack(spacing: 6) {
                Image(systemName: "bolt.shield.fill")
                    .foregroundColor(.blue)
                Text("Discord AMD Hackintosh Fix")
            }
        ) {
            VStack(alignment: .leading, spacing: 10) {
                // Status Section
                VStack(spacing: 8) {
                    HStack {
                        Text("Settings Config:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        statusBadge(for: state.discordSettingsStatus)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("GPU Wrapper:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("discord_ binary + Info.plist")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        statusBadge(for: state.discordPlistStatus)
                    }
                }
                .padding(.vertical, 2)
                
                Divider()
                
                // Login items toggle
                Toggle(isOn: Binding(
                    get: { state.autoPatchOnLogin },
                    set: { state.toggleAutoPatchOnLogin($0) }
                )) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Auto-patch on startup")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Verifies and re-applies patch on boot")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
                .padding(.vertical, 2)
                
                Divider()
                
                // Discord auto-update missing wrapper warning
                if state.discordSettingsStatus == "Patched" && state.discordPlistStatus == "Unpatched" {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "BF5AF2"))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Discord Wrapper Missing")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            Text("Discord auto-updated. Re-apply wrapper to restore hardware acceleration.")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            state.reApplyWrapper()
                        }) {
                            Text("Fix Now")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .buttonStyle(Physical3DButtonStyle(baseColor: Color(hex: "BF5AF2"), isProminent: true))
                    }
                    .padding(10)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.black.opacity(0.25))
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "BF5AF2").opacity(0.08), Color(hex: "BF5AF2").opacity(0.01)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "BF5AF2").opacity(0.25), .clear, .black.opacity(0.35)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                }
                
                // Main Actions Row
                HStack(spacing: 8) {
                    Button(action: {
                        state.patchDiscord()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "wand.and.stars")
                            Text("Patch Now")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Physical3DButtonStyle(baseColor: Color(hex: "0A84FF"), isProminent: true))
                    
                    Button(action: {
                        state.restoreDiscord()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Restore")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Physical3DButtonStyle(baseColor: .gray, isProminent: false))
                }
                
                // Secondary Utilities Row
                HStack(spacing: 8) {
                    Button(action: {
                        let path = NSString(string: "~/Library/Application Support/discord").expandingTildeInPath
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
                    }) {
                        Label("Config Folder", systemImage: "folder.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Physical3DButtonStyle(baseColor: .gray, isProminent: false))
                    
                    Button(action: {
                        state.reApplyWrapper()
                    }) {
                        Label("Re-Apply Wrapper", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Physical3DButtonStyle(baseColor: .gray, isProminent: false))
                    
                    Button(action: {
                        state.checkDiscordStatus()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(Physical3DButtonStyle(baseColor: .gray, isProminent: false))
                    .help("Refresh Status")
                }
                
                Divider()
                
                // Fix Stuck Update Section
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "FF9F0A").opacity(0.9))
                        Text("Discord Stuck on Update?")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "FF9F0A").opacity(0.9))
                    }
                    Text("Hackintosh network driver sering gagal download update Discord. Tombol ini download via curl & install otomatis.")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if state.discordUpdateTask.isRunning {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: state.discordUpdateTask.progress) {
                                HStack {
                                    Text(state.discordUpdateTask.status)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(Int(state.discordUpdateTask.progress * 100))%")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: "FF9F0A"))
                                }
                            }
                            .tint(Color(hex: "FF9F0A"))
                            
                            Button(action: { state.cancelDiscordUpdate() }) {
                                Label("Cancel", systemImage: "xmark.circle.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    } else {
                        Button(action: { state.runDiscordFixUpdate() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 12))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Fix Stuck Update")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("Download & install Discord terbaru via curl")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(Physical3DButtonStyle(baseColor: Color(hex: "FF9F0A"), isProminent: false))
                        
                        if state.discordUpdateTask.status.contains("updated") || state.discordUpdateTask.status.contains("GPU patch") {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 10))
                                Text(state.discordUpdateTask.status)
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .padding(10)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.03), .white.opacity(0.01)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "FF9F0A").opacity(0.18), .clear, .black.opacity(0.35)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
            }
            .padding(.top, 2)
        }
        .groupBoxStyle(AestheticGroupBoxStyle())
    }
    
    @ViewBuilder
    private func statusBadge(for status: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color(for: status))
                .frame(width: 6, height: 6)
                .shadow(color: color(for: status).opacity(0.4), radius: 2)
            
            Text(status)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(color(for: status))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color(for: status).opacity(0.12))
        .cornerRadius(6)
    }
    
    private func color(for status: String) -> Color {
        switch status {
        case "Patched":
            return .green
        case "Unpatched":
            return Color(hex: "FF9F0A")
        case "Discord Not Found":
            return .gray
        case "Permissions Needed":
            return .red
        case "Patching...", "Restoring...":
            return .blue
        default:
            return .secondary
        }
    }
}
