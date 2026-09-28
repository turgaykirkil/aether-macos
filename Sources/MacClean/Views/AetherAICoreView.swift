import SwiftUI

public struct AetherAICoreView: View {
    @EnvironmentObject var mainVM: MainViewModel
    @StateObject private var lang = LanguageManager.shared
    @StateObject private var boosterVM = AIBoosterViewModel()
    
    @State private var promptText: String = ""
    @State private var isProcessing: Bool = false
    @State private var aiLogs: [AILogEntry] = [
        AILogEntry(type: .system, message: "Aether Neural Engine 2.0 initialized on Apple Silicon Neural Engine (ANE)."),
        AILogEntry(type: .thought, message: "Workspace Armor active: 4 active developer repositories protected."),
        AILogEntry(type: .ready, message: "Micro-SLM ready for on-device reasoning and natural language cleanup commands.")
    ]
    
    @State private var orbRotation: Double = 0
    @State private var orbPulse: CGFloat = 1.0
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(lang.localized("Aether AI Neural Core", "Aether Yapay Zeka Çekirdeği"))
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                            
                            Text("ON-DEVICE SLM")
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(LinearGradient(colors: [Color.purple, Color.cyan], startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        
                        Text(lang.localized(
                            "Dedicated domain micro-language model operating entirely on Apple Neural Engine. Zero cloud, 100% private.",
                            "Doğrudan Apple Neural Engine üzerinde çalışan alana özel mikro dil modeli. Sıfır bulut, %100 gizli ve yerel."
                        ))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                // Neural Core Telemetry HUD
                HStack(spacing: 14) {
                    TelemetryCard(
                        title: lang.localized("Neural Engine", "Sinir Ağı Motoru"),
                        value: "Apple Silicon ANE",
                        subtitle: "M1/M2/M3/M4 CoreML",
                        icon: "cpu.fill",
                        color: .purple
                    )
                    TelemetryCard(
                        title: lang.localized("SLM Model", "Mikro-SLM"),
                        value: "Aether-SLM 0.5B",
                        subtitle: "4-bit Quantized Tensor",
                        icon: "brain.head.profile",
                        color: .cyan
                    )
                    TelemetryCard(
                        title: lang.localized("Inference Speed", "Çıkarım Hızı"),
                        value: "0.7 ms",
                        subtitle: "Ultra Low Latency",
                        icon: "bolt.horizontal.fill",
                        color: .green
                    )
                    TelemetryCard(
                        title: lang.localized("Privacy Level", "Gizlilik Seviyesi"),
                        value: "100% On-Device",
                        subtitle: "Zero Telemetry / Offline",
                        icon: "lock.shield.fill",
                        color: .blue
                    )
                }
                
                // Interactive Neural Orb & Command Console
                GlassCard {
                    VStack(spacing: 18) {
                        HStack(spacing: 20) {
                            // Pulsing 3D Liquid Orb
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color.cyan.opacity(0.8), Color.purple.opacity(0.6), Color.blue.opacity(0.2)],
                                            center: .center,
                                            startRadius: 5,
                                            endRadius: 45
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .scaleEffect(orbPulse)
                                    .blur(radius: 2)
                                
                                Circle()
                                    .stroke(
                                        AngularGradient(
                                            gradient: Gradient(colors: [Color.cyan, Color.purple, Color.pink, Color.cyan]),
                                            center: .center
                                        ),
                                        lineWidth: 3
                                    )
                                    .frame(width: 86, height: 86)
                                    .rotationEffect(.degrees(orbRotation))
                                
                                Image(systemName: "atom")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .cyan, radius: 8, x: 0, y: 0)
                            }
                            .padding(.leading, 6)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(lang.localized("Aether Neural Copilot", "Aether Yapay Zeka Asistanı"))
                                    .font(.system(size: 16, weight: .bold))
                                
                                Text(lang.localized(
                                    "Type natural instructions to diagnose system bottlenecks, purge inactive caches, or protect dev repositories.",
                                    "Sistem darboğazlarını teşhis etmek, gereksiz önbellekleri boşaltmak veya projelerinizi korumak için doğal dilde yazın."
                                ))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                
                                // Quick intent prompt chips
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        IntentChip(text: lang.localized("⚡ Optimize Memory for AI", "⚡ AI İçin RAM Optimize Et")) {
                                            runPrompt(lang.localized("Optimize Unified RAM and flush caches", "Birleşik belleği optimize et ve önbelleği boşalt"))
                                        }
                                        IntentChip(text: lang.localized("🚀 Deep System Analysis", "🚀 Derin Sistem Analizi Yap")) {
                                            runPrompt(lang.localized("Run deep system scan and find cleanable items", "Derin sistem taraması yap ve temizlenebilirleri bul"))
                                        }
                                        IntentChip(text: lang.localized("📁 Find Large DMG & Videos", "📁 Büyük DMG ve Videoları Bul")) {
                                            runPrompt(lang.localized("Find large installers and videos above 100MB", "100MB üstü büyük arşiv ve videoları bul"))
                                        }
                                        IntentChip(text: lang.localized("🛡️ Inspect Project Armor", "🛡️ Proje Kalkanını İncele")) {
                                            runPrompt(lang.localized("Check active developer project shields", "Aktif proje kalkanlarını denetle"))
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        
                        // Input bar
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                                .font(.system(size: 14))
                            
                            TextField(
                                lang.localized("Ask Aether Neural SLM to inspect, clean, or boost...", "Aether Yapay Zekasına incele, temizle veya hızlandır de..."),
                                text: $promptText
                            )
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .onSubmit {
                                runPrompt(promptText)
                            }
                            
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .controlSize(.small)
                            } else {
                                Button(action: {
                                    runPrompt(promptText)
                                }) {
                                    HStack(spacing: 4) {
                                        Text(lang.localized("Execute", "Çalıştır"))
                                        Image(systemName: "arrow.right.circle.fill")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.purple)
                                .clipShape(Capsule())
                                .disabled(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                        .cornerRadius(10)
                    }
                }
                
                // Real-time Neural Audit Log Console
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "terminal.fill")
                            .foregroundColor(.cyan)
                        Text(lang.localized("Neural Engine Reasoning & Live Audit", "Yapay Zeka Karar & Canlı Denetim Günlüğü"))
                            .font(.system(size: 14, weight: .bold))
                        Spacer()
                        
                        Button(action: {
                            aiLogs.removeAll()
                        }) {
                            Text(lang.localized("Clear Log", "Günlüğü Temizle"))
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(aiLogs) { log in
                            HStack(alignment: .top, spacing: 10) {
                                Text(log.timestamp, style: .time)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Text(log.tag)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1.5)
                                    .background(log.typeColor.opacity(0.15))
                                    .foregroundColor(log.typeColor)
                                    .cornerRadius(3)
                                
                                Text(log.message)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.primary.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                orbRotation = 360
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                orbPulse = 1.08
            }
        }
    }
    
    private func runPrompt(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        self.promptText = text
        isProcessing = true
        
        let intent = AetherNeuralEngine.shared.parseCleaningIntent(prompt: text)
        aiLogs.append(AILogEntry(type: .user, message: "User Query: \"\(text)\""))
        aiLogs.append(AILogEntry(type: .thought, message: "Tokenizing query -> Intent: [\(intent.actionType)] Category: [\(intent.targetCategory ?? "Global")]"))
        aiLogs.append(AILogEntry(type: .system, message: intent.explanation))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isProcessing = false
            switch intent.actionType {
            case "BOOST_RAM":
                Task {
                    await boosterVM.triggerTurboBoost()
                    aiLogs.append(AILogEntry(type: .ready, message: "Turbo Boost executed via Neural Core."))
                }
            case "FIND_LARGE_FILES":
                mainVM.selectedCategory = .largeFiles
                aiLogs.append(AILogEntry(type: .ready, message: "Navigating to Large Files Scanner."))
            case "CLEAN_CACHES":
                mainVM.selectedCategory = .aiAndDev
                aiLogs.append(AILogEntry(type: .ready, message: "Targeting Developer & AI caches."))
            default:
                mainVM.selectedCategory = .dashboard
                aiLogs.append(AILogEntry(type: .ready, message: "Starting Neural Smart Scan on Macintosh HD."))
            }
            self.promptText = ""
        }
    }
}

// MARK: - Subcomponents
struct TelemetryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        GlassCard(padding: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                }
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct IntentChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.purple.opacity(0.15))
                .foregroundColor(.purple)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

enum LogType {
    case user, thought, system, ready
}

struct AILogEntry: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let type: LogType
    let message: String
    
    var tag: String {
        switch type {
        case .user: return "USER"
        case .thought: return "REASON"
        case .system: return "KERNEL"
        case .ready: return "ACTION"
        }
    }
    
    var typeColor: Color {
        switch type {
        case .user: return .blue
        case .thought: return .purple
        case .system: return .cyan
        case .ready: return .green
        }
    }
}
