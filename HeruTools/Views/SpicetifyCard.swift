import SwiftUI

struct SpicetifyCard: View {
    @ObservedObject var state = AppState.shared
    
    var body: some View {
        GroupBox(label: 
            HStack(spacing: 6) {
                Image(systemName: "music.note.house.fill")
                    .foregroundColor(.green)
                Text("Spicetify CLI Toolkit")
            }
        ) {
            VStack(alignment: .leading, spacing: 10) {
                // Status Section
                HStack {
                    Text("Spicetify Integration:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    statusBadge(for: state.spicetifyStatus)
                }
                .padding(.vertical, 4)
                
                Divider()
                
                // Active status loader
                if state.spicetifyStatus == "Installing..." || 
                   state.spicetifyStatus == "Restoring..." || 
                   state.spicetifyStatus == "Updating..." || 
                   state.spicetifyStatus == "Backing up..." {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(state.spicetifyStatus)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    // Actions Grid
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Button(action: {
                                state.installSpicetify()
                            }) {
                                Label("Install Spicetify", systemImage: "plus.square.fill.on.square.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .controlSize(.regular)
                            .disabled(state.spicetifyStatus == "Spotify Not Found")
                            
                            Button(action: {
                                state.restoreSpicetify()
                            }) {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .disabled(state.spicetifyStatus == "Spotify Not Found" || state.spicetifyStatus == "Missing")
                        }
                        
                        HStack(spacing: 8) {
                            Button(action: {
                                state.updateSpicetify()
                            }) {
                                Label("Update Core", systemImage: "arrow.up.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .disabled(state.spicetifyStatus == "Spotify Not Found" || state.spicetifyStatus == "Missing")
                            
                            Button(action: {
                                state.backupSpicetify()
                            }) {
                                Label("Backup Config", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .disabled(state.spicetifyStatus == "Spotify Not Found" || state.spicetifyStatus == "Missing")
                        }
                    }
                }
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
        case "Installed":
            return .green
        case "Patched (No Backup)":
            return .teal
        case "Missing":
            return .orange
        case "Spotify Not Found":
            return .red
        case "Checking...":
            return .gray
        case "Installing...", "Restoring...", "Updating...", "Backing up...":
            return .blue
        default:
            return .secondary
        }
    }
}
