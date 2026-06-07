import SwiftUI

struct LargeFilesTab: View {
    @StateObject private var vm = LargeFilesVM()

    var body: some View {
        VStack(spacing: 8) {
            // Threshold selector
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text("Min Size:")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Picker("", selection: $vm.minSizeMB) {
                        Text("50 MB").tag(Int64(50))
                        Text("100 MB").tag(Int64(100))
                        Text("200 MB").tag(Int64(200))
                        Text("500 MB").tag(Int64(500))
                        Text("1 GB").tag(Int64(1024))
                    }
                    .pickerStyle(.menu)
                    .frame(width: 90)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.black.opacity(0.35))
                        
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    }
                )
                
                Spacer()
                
                Button(action: { Task { await vm.scan() } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                        Text(vm.isScanning ? "Scanning..." : "Scan")
                    }
                }
                .buttonStyle(Physical3DButtonStyle(baseColor: Color(hex: "0A84FF"), isProminent: true))
                .disabled(vm.isScanning)
            }

            if vm.isScanning {
                RadarScannerView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.files.isEmpty {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.2), Color.mint.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                Circle().strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
                            )
                            .frame(width: 48, height: 48)
                            .shadow(color: Color.green.opacity(0.3), radius: 5)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
                            )
                    }
                    
                    Text(vm.didScan ? "No large files found!" : "Tap Scan to find large files")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Results list
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 5) {
                        ForEach(vm.files) { file in
                            LargeFileRow(file: file)
                        }
                    }
                }
                
                Text("\(vm.files.count) files found (top 50 largest)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
