import SwiftUI
import UniformTypeIdentifiers

struct CompressorCard: View {
    @ObservedObject var state = AppState.shared
    
    @State private var droppedURL: URL?
    @State private var isTargeted = false
    
    // Compression Settings
    @State private var selectedPreset = "medium"
    @State private var selectedCodec = "h264"
    @State private var removeAudio = false
    @State private var useCustomTargetSize = false
    @State private var targetSizeMB = "25"
    
    var body: some View {
        GroupBox(label: 
            HStack(spacing: 6) {
                Image(systemName: "video.badge.plus.fill")
                    .foregroundColor(.orange)
                Text("FFmpeg Video Compressor")
            }
        ) {
            VStack(alignment: .leading, spacing: 10) {
                // Drag & Drop Box
                dropZoneView
                
                if droppedURL != nil {
                    // Controls Grid
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Preset Quality:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("", selection: $selectedPreset) {
                                Text("Small").tag("small")
                                Text("Medium").tag("medium")
                                Text("High").tag("high")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 150)
                        }
                        
                        HStack {
                            Text("Target Codec:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("", selection: $selectedCodec) {
                                Text("H264").tag("h264")
                                Text("HEVC").tag("hevc")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 150)
                        }
                        
                        Divider()
                            .padding(.vertical, 2)
                        
                        // Clean Vertically Stacked Toggles (Solving the horizontal cramped checkbox layout)
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Remove audio track from video", isOn: $removeAudio)
                                .toggleStyle(.checkbox)
                                .font(.system(size: 11, weight: .semibold))
                            
                            Toggle("Enforce custom output size limit", isOn: $useCustomTargetSize.animation())
                                .toggleStyle(.checkbox)
                                .font(.system(size: 11, weight: .semibold))
                            
                            if useCustomTargetSize {
                                HStack {
                                    Text("Enter target limit:")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 18)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        TextField("25", text: $targetSizeMB)
                                            .textFieldStyle(.roundedBorder)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 50)
                                        Text("MB")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                    }
                    .padding(.vertical, 2)
                    
                    Divider()
                    
                    // Encoding Progress Panel
                    if state.compressorTask.isRunning {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: state.compressorTask.progress) {
                                HStack {
                                    Text(state.compressorTask.status)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(Int(state.compressorTask.progress * 100))%")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                }
                            }
                            
                            HStack {
                                Text("Est. Size: \(state.compressorTask.outputEstimatedSize)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Label("ETA: \(state.compressorTask.eta)", systemImage: "clock")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    state.cancelCompressor()
                                }) {
                                    Text("Cancel")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                                .controlSize(.small)
                            }
                        }
                        .padding(.vertical, 2)
                    } else {
                        HStack(spacing: 8) {
                            Button(action: {
                                if let url = droppedURL {
                                    let size = useCustomTargetSize ? Double(targetSizeMB) : nil
                                    state.runCompressor(
                                        inputPath: url.path,
                                        preset: selectedPreset,
                                        codec: selectedCodec,
                                        removeAudio: removeAudio,
                                        targetSize: size
                                    )
                                }
                            }) {
                                Label("Compress Video", systemImage: "arrow.down.right.and.arrow.up.left")
                                    .font(.system(size: 12, weight: .bold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .controlSize(.regular)
                            
                            if state.compressorTask.status.contains("Finished") {
                                Button(action: {
                                    if let url = droppedURL {
                                        let outputFolder = url.deletingLastPathComponent().path
                                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: outputFolder)
                                    }
                                }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.regular)
                                .help("Reveal in Finder")
                            }
                        }
                    }
                }
            }
            .padding(.top, 2)
        }
        .groupBoxStyle(AestheticGroupBoxStyle())
    }
    
    private var dropZoneView: some View {
        VStack(spacing: 6) {
            if let file = droppedURL {
                HStack(spacing: 8) {
                    Image(systemName: "video.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.lastPathComponent)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                        Text(file.path)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Button(action: {
                        droppedURL = nil
                        state.compressorTask.status = "Idle"
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(8)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isTargeted ? .orange : .secondary)
                        .scaleEffect(isTargeted ? 1.05 : 1.0)
                        .animation(.spring(), value: isTargeted)
                    
                    Text("Drag & Drop Video Here")
                        .font(.system(size: 12, weight: .semibold))
                    
                    Text("Optimizes standard MP4, MOV, MKV files")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isTargeted ? Color.orange : Color.secondary.opacity(0.2),
                            style: StrokeStyle(lineWidth: 1.5, dash: [4])
                        )
                )
                .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
                    guard let provider = providers.first else { return false }
                    _ = provider.loadObject(ofClass: URL.self) { url, error in
                        DispatchQueue.main.async {
                            if let rawUrl = url {
                                if rawUrl.scheme == "file" {
                                    self.droppedURL = rawUrl
                                } else {
                                    self.droppedURL = URL(fileURLWithPath: rawUrl.path)
                                }
                            }
                        }
                    }
                    return true
                }
            }
        }
    }
}
