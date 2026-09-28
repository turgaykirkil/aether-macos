import SwiftUI

public struct GlassCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let padding: CGFloat
    
    public init(cornerRadius: CGFloat = 18, padding: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // 1. Derinlik ve Taban Rengi
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(nsColor: .windowBackgroundColor).opacity(0.42))
                    
                    // 2. Ultra-Thin Buzlu Akrilik Cam
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            )
            .overlay(
                // 3. Liquid Glass Işık Kırılmalı Speküler Kenarlık
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.cyan.opacity(0.18),
                                Color.purple.opacity(0.15),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
    }
}
