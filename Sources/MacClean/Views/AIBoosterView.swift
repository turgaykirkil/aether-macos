import SwiftUI

public struct AIBoosterView: View {
    @StateObject private var vm = AIBoosterViewModel()
    @StateObject private var lang = LanguageManager.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(lang.localized("AI & Dev RAM Turbo Booster", "AI & Dev RAM Booster"))
                        .font(.system(size: 22, weight: .bold))
                    Text(lang.localized(
                        "Flush inactive kernel memory and optimize Unified RAM for large local LLMs (Ollama, LM Studio) and intensive builds.",
                        "Büyük Yapay Zeka modelleri (Ollama, LM Studio) ve ağır derlemeler (Xcode, Docker, Rust) için RAM'i tek tıkla optimize edin."
                    ))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                }
                
                // Turbo Boost Hero Card
                GlassCard {
                    HStack(spacing: 24) {
                        GaugeRingView(
                            progress: vm.memoryStats.pressurePercentage,
                            title: lang.localized("RAM Pressure", "Bellek Baskısı"),
                            subtitle: "\(vm.memoryStats.pressureText)",
                            color: vm.memoryStats.pressureColor
                        )
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(lang.localized("AI & Dev Turbo Boost Mode", "AI & Dev Turbo Boost Modu"))
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                                
                                Toggle(lang.localized("Live Monitor", "Canlı İzleme"), isOn: $vm.autoRefreshEnabled)
                                    .toggleStyle(.switch)
                                    .font(.system(size: 11))
                            }
                            
                            Text(lang.localized(
                                "Purges inactive disk cache pages and recycles memory buffers instantly via macOS kernel VM routines.",
                                "İnaktif disk önbelleklerini ve uyuyan arka plan süreçlerini temizleyerek Birleşik Belleği (Unified RAM) anında yerel yapay zeka ve derleme görevlerinize açar."
                            ))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    Task {
                                        await vm.triggerTurboBoost()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        if vm.isBoosting {
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                                .controlSize(.small)
                                        } else {
                                            Image(systemName: "bolt.fill")
                                        }
                                        Text(vm.isBoosting ? lang.localized("Optimizing...", "Optimize Ediliyor...") : lang.localized("Optimize Unified RAM", "Belleği Optimize Et (Turbo Boost)"))
                                            .font(.system(size: 13, weight: .bold))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .disabled(vm.isBoosting)
                                
                                Button(action: {
                                    vm.refresh()
                                }) {
                                    Label(lang.localized("Refresh", "Yenile"), systemImage: "arrow.clockwise")
                                        .font(.system(size: 12))
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                
                // Memory Breakdown Grid
                VStack(alignment: .leading, spacing: 10) {
                    Text(lang.localized("macOS Unified Memory Distribution", "macOS Birleşik Bellek Dağılımı"))
                        .font(.system(size: 14, weight: .semibold))
                    
                    HStack(spacing: 12) {
                        MemoryStatBox(title: lang.localized("Total RAM", "Toplam RAM"), value: vm.memoryStats.formattedTotal, icon: "memorychip", color: .blue)
                        MemoryStatBox(title: lang.localized("Active RAM", "Aktif RAM"), value: vm.memoryStats.formattedUsed, icon: "flame.fill", color: .orange)
                        MemoryStatBox(title: lang.localized("Inactive / Cache", "İnaktif / Önbellek"), value: vm.memoryStats.formattedInactive, icon: "arrow.triangle.2.circlepath", color: .purple)
                        MemoryStatBox(title: lang.localized("Free RAM", "Serbest RAM"), value: vm.memoryStats.formattedFree, icon: "sparkles", color: .green)
                    }
                }
                
                // Heavy Background Processes Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.localized("Top Memory-Consuming Processes", "En Çok Bellek Tüketen Süreçler & Servisler"))
                                .font(.system(size: 14, weight: .semibold))
                            Text(lang.localized(
                                "Terminate memory hogs to maximize allocation for local LLMs and simulators.",
                                "Yapay zeka modellerini rahatlatmak için kapatmak istediğiniz arka plan süreçlerini seçebilirsiniz."
                            ))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    VStack(spacing: 6) {
                        ForEach(vm.heavyProcesses) { proc in
                            HStack(spacing: 12) {
                                Button(action: {
                                    if let idx = vm.heavyProcesses.firstIndex(where: { $0.id == proc.id }) {
                                        vm.heavyProcesses[idx].isSelected.toggle()
                                    }
                                }) {
                                    Image(systemName: proc.isSelected ? "checkmark.square.fill" : "square")
                                        .foregroundColor(proc.isSelected ? .green : .gray)
                                        .font(.system(size: 15))
                                }
                                .buttonStyle(.plain)
                                .disabled(proc.isSystemProcess)
                                
                                Image(systemName: proc.isSystemProcess ? "gearshape.fill" : "app.fill")
                                    .foregroundColor(proc.isSystemProcess ? .secondary : .green)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(proc.name)
                                            .font(.system(size: 12, weight: .medium))
                                        if proc.isSystemProcess {
                                            Text(lang.localized("System", "Sistem"))
                                                .font(.system(size: 9))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.secondary.opacity(0.12))
                                                .cornerRadius(3)
                                        }
                                    }
                                    Text("PID: \(proc.id) • CPU: %\(String(format: "%.1f", proc.cpuPercent))")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(proc.formattedMemory)
                                    .font(.system(size: 12, weight: .semibold))
                                
                                if !proc.isSystemProcess {
                                    Button(action: {
                                        vm.killProcess(proc)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red.opacity(0.8))
                                    }
                                    .buttonStyle(.plain)
                                    .help(lang.localized("Terminate process", "Süreci sonlandır"))
                                }
                            }
                            .padding(10)
                            .background(Color.black.opacity(0.12))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(24)
        }
        .alert(lang.localized("AI & Dev Turbo Boost", "AI & Dev Turbo Boost"), isPresented: $vm.showBoostAlert) {
            Button(lang.localized("OK", "Tamam"), role: .cancel) {}
        } message: {
            Text(vm.lastBoostResult ?? "")
        }
    }
}

struct MemoryStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                }
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
