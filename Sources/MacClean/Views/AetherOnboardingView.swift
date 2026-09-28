import SwiftUI

public struct AetherOnboardingView: View {
    @Binding var isPresented: Bool
    @StateObject private var lang = LanguageManager.shared
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        ZStack {
            // Liquid Backdrop
            LinearGradient(
                colors: [Color.purple.opacity(0.2), Color.cyan.opacity(0.15), Color.black.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo & Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color.cyan, Color.purple, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 72, height: 72)
                            .shadow(color: Color.cyan.opacity(0.6), radius: 16, x: 0, y: 4)
                        
                        Image(systemName: "atom")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Aether")
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                            Text("2.0")
                                .font(.system(size: 11, weight: .heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        
                        Text(lang.localized(
                            "Next-Gen Neural macOS Optimizer & On-Device AI Core",
                            "Yeni Nesil Sinir Ağı Destekli macOS Optimizasyon Aracı"
                        ))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    }
                }
                
                // 4 Pillars of Aether
                VStack(spacing: 14) {
                    FeatureRow(
                        icon: "brain.head.profile",
                        color: .purple,
                        title: lang.localized("On-Device Micro-SLM Intelligence", "Cihaz İçi Mikro-SLM Yapay Zekası"),
                        desc: lang.localized("Runs on Apple Neural Engine (ANE). Assesses file safety with zero cloud data transmission.", "Doğrudan Apple Neural Engine üzerinde çalışır. Sıfır bulut ile dosyaların güvenliğini değerlendirir.")
                    )
                    
                    FeatureRow(
                        icon: "lock.shield.fill",
                        color: .green,
                        title: lang.localized("Zero-Risk Developer Armor", "Sıfır Riskli Geliştirici Kalkanı"),
                        desc: lang.localized("Active projects, Docker/Cloudflare tunnels, and recent repos are automatically protected.", "Aktif projeleriniz, tüneller ve terminal servisleri otomatik olarak korunur.")
                    )
                    
                    FeatureRow(
                        icon: "bolt.shield.fill",
                        color: .yellow,
                        title: lang.localized("Unified RAM Turbo Booster", "Birleşik Bellek (RAM) Hızlandırıcı"),
                        desc: lang.localized("Active kernel VM cache recycling frees up gigabytes of buffer memory for local LLMs and builds.", "Aktif çekirdek bellek döngüsüyle büyük dil modelleri ve derlemeler için RAM'i rahatlatır.")
                    )
                    
                    FeatureRow(
                        icon: "sparkles",
                        color: .cyan,
                        title: lang.localized("100% Native Liquid Glass Architecture", "100% Native Likit Cam Tasarımı"),
                        desc: lang.localized("Crafted with pure Swift & SwiftUI. Ultra-fast, lightweight (<3 MB), zero Electron bloat.", "Saf Swift ve SwiftUI ile yazılmıştır. Ultra hafif (<3 MB), aşırı hızlı ve şeffaf.")
                    )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                )
                
                // Action Button
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text(lang.localized("Explore Aether ➔", "Aether'ı Keşfetmeye Başla ➔"))
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 4)
            }
            .padding(32)
            .frame(width: 520)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}
