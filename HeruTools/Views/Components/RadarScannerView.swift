import SwiftUI

struct RadarScannerView: View {
    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 0.8
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color(hex: "0A84FF").opacity(0.15), lineWidth: 1.5)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .stroke(Color(hex: "0A84FF").opacity(0.3), lineWidth: 1)
                    .frame(width: 40, height: 40)
                    .scaleEffect(pulse)
                    .opacity(2.0 - Double(pulse))
                
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(
                        AngularGradient(
                            colors: [Color(hex: "0A84FF"), Color(hex: "0A84FF").opacity(0)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(rotation))
                
                Path { path in
                    path.move(to: CGPoint(x: 30, y: 0))
                    path.addLine(to: CGPoint(x: 30, y: 60))
                    path.move(to: CGPoint(x: 0, y: 30))
                    path.addLine(to: CGPoint(x: 60, y: 30))
                }
                .stroke(Color(hex: "0A84FF").opacity(0.1), lineWidth: 0.7)
                .frame(width: 60, height: 60)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "0A84FF"))
                    .shadow(color: Color(hex: "0A84FF").opacity(0.5), radius: 3)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulse = 1.3
                }
            }
            
            Text("Scanning system directories...")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
