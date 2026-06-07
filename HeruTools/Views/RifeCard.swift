import SwiftUI
import UniformTypeIdentifiers

struct RifeCard: View {
    @ObservedObject var state = AppState.shared
    
    @State private var droppedURL: URL?
    @State private var isTargeted = false
    @State private var fpsFactor = 2.0
    @State private var selectedModel = "rife-v4.6"
    @State private var crfValue = 22.0 // Matched exactly from your screenshot!
    
    var body: some View {
        GroupBox(label: 
            HStack(spacing: 6) {
                Image(systemName: "square.stack.3d.forward.dotted.line.fill")
                    .foregroundColor(.purple)
                Text("RIFE Frame Interpolation")
            }
        ) {
            VStack(alignment: .leading, spacing: 10) {
                // Drag & Drop Area
                dropZoneView
                
                if droppedURL != nil {
                    // Settings Panel
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Scale Multiplier:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("", selection: $fpsFactor) {
                                Text("2x FPS").tag(2.0)
                                Text("4x FPS").tag(4.0)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 140)
                        }
                        
                        HStack {
                            Text("Interpolation Model:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("", selection: $selectedModel) {
                                Text("v4.6 (Recommended)").tag("rife-v4.6")
                                Text("v4.15 Lite").tag("rife-v4.15-lite")
                                Text("v3.1 Classic").tag("rife-v3.1")
                                Text("v2.4 Classic").tag("rife-v2.4")
                                Text("rife-anime").tag("rife-anime")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 160)
                        }
                        
                        Divider()
                            .padding(.vertical, 2)
                        
                        // Premium Constant Quality (RF) Slider (Matched from screenshot)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Quality:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "largecircle.fill.circle")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 11))
                                    Text("Constant Quality")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .padding(.leading, 4)
                                
                                Spacer()
                                
                                Text("RF  \(Int(crfValue))")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.blue)
                            }
                            
                            Slider(value: $crfValue, in: 15...30, step: 1)
                                .tint(.blue)
                                .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 2)
                    
                    Divider()
                    
                    // Task Progress & Commands
                    if state.rifeTask.isRunning {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: state.rifeTask.progress) {
                                HStack {
                                    Text(state.rifeTask.status)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(Int(state.rifeTask.progress * 100))%")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                }
                            }
                            
                            HStack {
                                Label("ETA: \(state.rifeTask.eta)", systemImage: "clock")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    state.cancelRife()
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
                                    state.runRife(
                                        inputPath: url.path, 
                                        fpsFactor: fpsFactor, 
                                        model: selectedModel, 
                                        crf: Int(crfValue)
                                    )
                                }
                            }) {
                                Label("Interpolate Video", systemImage: "play.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            .controlSize(.regular)
                            
                            if state.rifeTask.status.contains("Finished") {
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
                        .foregroundColor(.purple)
                    
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
                        state.rifeTask.status = "Idle"
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(Color.purple.opacity(0.08))
                .cornerRadius(8)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isTargeted ? .purple : .secondary)
                        .scaleEffect(isTargeted ? 1.05 : 1.0)
                        .animation(.spring(), value: isTargeted)
                    
                    Text("Drag & Drop Video Here")
                        .font(.system(size: 12, weight: .semibold))
                    
                    Text("Accepts standard MP4, MOV, MKV formats")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isTargeted ? Color.purple : Color.secondary.opacity(0.2),
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
