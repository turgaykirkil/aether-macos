import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject var mainVM: MainViewModel
    @StateObject private var vm = DashboardViewModel()
    @StateObject private var boosterVM = AIBoosterViewModel()
    @StateObject private var lang = LanguageManager.shared
    @State private var showPermanentDeleteAlert = false
    @State private var neuralPromptText: String = ""
    @State private var neuralResponseFeedback: String? = nil
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Header with live status badge
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Aether")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 7, height: 7)
                                    .shadow(color: Color.green.opacity(0.8), radius: 4, x: 0, y: 0)
                                Text(lang.localized("SYSTEM HEALTHY", "SİSTEM SAĞLIKLI"))
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        
                        Text(lang.localized("On-Device Neural Engine & Intelligent macOS Optimization Core", "Cihaz içi Sinir Ağı Motoru ve Akıllı macOS Optimizasyon Merkezi"))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 2)
                
                // On-Device Micro-SLM Natural Language Intent Command Bar
                GlassCard(padding: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(colors: [Color.cyan, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 32, height: 32)
                                    .shadow(color: Color.cyan.opacity(0.4), radius: 6, x: 0, y: 2)
                                
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            TextField(
                                lang.localized(
                                    "Ask Aether Micro-SLM (e.g. 'Optimize memory for Ollama', 'Clean dev caches')...",
                                    "Aether Sinir Ağına Sor (ör. 'Belleği optimize et', 'Geliştirici önbelleklerini temizle')..."
                                ),
                                text: $neuralPromptText
                            )
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .onSubmit {
                                executeNeuralIntent()
                            }
                            
                            Button(action: {
                                executeNeuralIntent()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                    Text(lang.localized("Run SLM", "Çalıştır"))
                                }
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            .clipShape(Capsule())
                        }
                        
                        if let feedback = neuralResponseFeedback {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 12))
                                Text(feedback)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                
                // Visual Storage Breakdown Bar Card
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Image(systemName: "internaldrive.fill")
                                        .foregroundColor(.pink)
                                    Text("Macintosh HD Depolama Haritası")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                Text("Toplam: \(mainVM.formattedTotalDisk) • Kullanılan: \(mainVM.formattedUsedDisk) • Boş: \(mainVM.formattedFreeDisk)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    mainVM.selectedCategory = .systemData
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkle.magnifyingglass")
                                    Text("Sistem Verilerini Aç (\(mainVM.formattedSystemDataSize))")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.pink)
                            .shadow(color: Color.pink.opacity(0.3), radius: 6, x: 0, y: 2)
                        }
                        
                        StorageBreakdownBar(
                            totalBytes: mainVM.totalDiskSpace,
                            usedBytes: mainVM.usedDiskSpace,
                            freeBytes: mainVM.freeDiskSpace
                        )
                    }
                }
                
                // Top Dual Gauges (Disk & Unified RAM)
                HStack(spacing: 16) {
                    // Disk Gauge Card
                    GlassCard {
                        HStack(spacing: 18) {
                            GaugeRingView(
                                progress: mainVM.usedDiskPercentage,
                                title: "Kullanılan",
                                subtitle: "\(mainVM.formattedUsedDisk) / \(mainVM.formattedTotalDisk)",
                                color: .blue
                            )
                            
                            VStack(alignment: .leading, spacing: 7) {
                                Text("Disk Doluluk Durumu")
                                    .font(.system(size: 14, weight: .bold))
                                
                                HStack(spacing: 6) {
                                    Circle().fill(Color.blue).frame(width: 8, height: 8)
                                    Text("Dolu: \(mainVM.formattedUsedDisk)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 6) {
                                    Circle().fill(Color.green).frame(width: 8, height: 8)
                                    Text("Boş: \(mainVM.formattedFreeDisk)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.green)
                                }
                            }
                            Spacer()
                        }
                    }
                    
                    // RAM Gauge Card
                    GlassCard {
                        HStack(spacing: 18) {
                            GaugeRingView(
                                progress: boosterVM.memoryStats.pressurePercentage,
                                title: "RAM Yükü",
                                subtitle: "\(boosterVM.memoryStats.formattedUsed) / \(boosterVM.memoryStats.formattedTotal)",
                                color: boosterVM.memoryStats.pressureColor
                            )
                            
                            VStack(alignment: .leading, spacing: 7) {
                                Text("Birleşik Bellek (Unified RAM)")
                                    .font(.system(size: 14, weight: .bold))
                                
                                HStack(spacing: 6) {
                                    Circle().fill(boosterVM.memoryStats.pressureColor).frame(width: 8, height: 8)
                                    Text("Durum: \(boosterVM.memoryStats.pressureText)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(boosterVM.memoryStats.pressureColor)
                                }
                                
                                Text("İnaktif Bellek: \(boosterVM.memoryStats.formattedInactive)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
                
                // Hero AI Smart Optimizer Banner Card
                GlassCard {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.8), Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 52, height: 52)
                                    .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 4)
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("Akıllı Sistem & Geliştirici Taraması")
                                        .font(.system(size: 16, weight: .bold))
                                    
                                    Text("PRO")
                                        .font(.system(size: 9, weight: .heavy))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .clipShape(Capsule())
                                }
                                
                                Text("Geliştirme projeleriniz kalkanla korunur. Yalnızca güvenli önbellekler, atıl loglar ve yetim artıklar incelenir.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                            
                            if vm.isScanning {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .controlSize(.regular)
                                    Text("Taranıyor...")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                            } else {
                                Button(action: {
                                    Task {
                                        await vm.startSmartScan()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: vm.scanCompleted ? "arrow.clockwise" : "bolt.fill")
                                        Text(vm.scanCompleted ? "Yeniden Tara" : "Akıllı Analizi Başlat")
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                .shadow(color: Color.blue.opacity(0.35), radius: 8, x: 0, y: 3)
                            }
                        }
                        
                        if vm.isScanning || !vm.statusText.isEmpty {
                            HStack {
                                Text(vm.statusText)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                
                // Results Section (if scanned)
                if vm.scanCompleted {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Temizlenebilir Güvenli Öğeler")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Seçili öğeler güvenle temizlenebilir veya çöp kutusuna taşınabilir.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("Seçilen: \(vm.formattedTotalCleanable)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.12))
                                .cornerRadius(6)
                            
                            // Dual Action Buttons: Çöp Kutusuna Taşı & Tamamen Sil
                            HStack(spacing: 8) {
                                Button(action: {
                                    Task {
                                        _ = await vm.cleanSelectedItems(mode: .trash)
                                        mainVM.refreshDiskSpace()
                                    }
                                }) {
                                    Label("Çöpe Taşı", systemImage: "trash")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .buttonStyle(.bordered)
                                .disabled(vm.totalCleanableBytes == 0 || vm.isCleaning)
                                .help("Seçilenleri macOS Çöp Kutusu'na gönder (Geri alınabilir)")
                                
                                Button(action: {
                                    showPermanentDeleteAlert = true
                                }) {
                                    Label("Tamamen Sil", systemImage: "flame.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                .disabled(vm.totalCleanableBytes == 0 || vm.isCleaning)
                                .help("Seçilenleri diskten kalıcı olarak sil")
                            }
                        }
                        
                        // Items List with Safety Badges
                        VStack(spacing: 8) {
                            ForEach(vm.systemJunkItems) { item in
                                CleanItemRowView(item: item) {
                                    if let idx = vm.systemJunkItems.firstIndex(where: { $0.id == item.id }) {
                                        vm.systemJunkItems[idx].isSelected.toggle()
                                    }
                                }
                            }
                            
                            ForEach(vm.developerItems) { item in
                                CleanItemRowView(item: item) {
                                    if let idx = vm.developerItems.firstIndex(where: { $0.id == item.id }) {
                                        vm.developerItems[idx].isSelected.toggle()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .alert("Kalıcı Silme Onayı", isPresented: $showPermanentDeleteAlert) {
            Button("Tamamen Sil (\(vm.formattedTotalCleanable))", role: .destructive) {
                Task {
                    _ = await vm.cleanSelectedItems(mode: .permanent)
                    mainVM.refreshDiskSpace()
                }
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Seçilen \(vm.formattedTotalCleanable) boyutundaki dosyalar doğrudan diskten KALICI OLARAK silinecektir.\n\nBu işlem geri alınamaz. Emin misiniz?")
        }
        .alert("Temizlik Tamamlandı", isPresented: $vm.showSuccessSheet) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(vm.statusText)
        }
    }
    
    private func executeNeuralIntent() {
        guard !neuralPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let intent = AetherNeuralEngine.shared.parseCleaningIntent(prompt: neuralPromptText)
        self.neuralResponseFeedback = intent.explanation
        
        switch intent.actionType {
        case "BOOST_RAM":
            Task {
                await boosterVM.triggerTurboBoost()
            }
        case "FIND_LARGE_FILES":
            mainVM.selectedCategory = .largeFiles
        case "CLEAN_CACHES":
            mainVM.selectedCategory = .aiAndDev
        default:
            Task {
                await vm.startSmartScan()
            }
        }
    }
}
