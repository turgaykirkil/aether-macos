import SwiftUI

public struct GaugeRingView: View {
    let progress: Double // 0 to 100
    let title: String
    let subtitle: String
    let color: Color
    
    public init(progress: Double, title: String, subtitle: String, color: Color = .blue) {
        self.progress = progress
        self.title = title
        self.subtitle = subtitle
        self.color = color
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(color.opacity(0.12), lineWidth: 9)
                
                // Progress Arc Glow
                Circle()
                    .trim(from: 0, to: CGFloat(min(1.0, max(0.0, progress / 100.0))))
                    .stroke(
                        color.opacity(0.3),
                        style: StrokeStyle(lineWidth: 13, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 3)
                
                // Progress Arc
                Circle()
                    .trim(from: 0, to: CGFloat(min(1.0, max(0.0, progress / 100.0))))
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.7), color, color.opacity(0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.75), value: progress)
                
                // Center text
                VStack(spacing: 1) {
                    Text("\(Int(progress))%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text(title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
            }
            .frame(width: 96, height: 96)
            
            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}
