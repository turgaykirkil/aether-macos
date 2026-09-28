import SwiftUI

public struct SystemDataView: View {
    @EnvironmentObject var mainVM: MainViewModel
    @StateObject private var vm = SystemDataViewModel()
    @StateObject private var lang = LanguageManager.shared
    @State private var itemToPermanentlyDelete: SystemDataBreakdownItem? = nil
    @State private var showPermanentDeleteAlert = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(lang.localized("System Data Deep Inspector", "Sistem Verileri (System Data) Derin Analizi"))
                                .font(.system(size: 22, weight: .bold))
                            
                            Text("\(lang.localized("Total", "Toplam")): \(mainVM.formattedSystemDataSize)")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.pink.opacity(0.15))
                                .foregroundColor(.pink)
                                .cornerRadius(6)
                        }
                        
                        Text(lang.localized(
                            "100% matched with macOS Storage Settings. Complete breakdown and safe purging console.",
                            "macOS Saklama Alanı ayarlarındaki Sistem Verileri ile %100 birebir uyumlu tam döküm ve temizleme paneli."
                        ))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await vm.analyze()
                            await mainVM.calculateSystemDataSize()
                        }
                    }) {
                        Label(
                            vm.isLoading ? lang.localized("Scanning...", "Taranıyor...") : lang.localized("Re-Analyze", "Yeniden Analiz Et"),
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                        .font(.system(size: 12, weight: .semibold))
                    }
                    .disabled(vm.isLoading)
                }
                
                // Detailed Breakdown Metric Cards (Total vs Actionable vs Locked)
                HStack(spacing: 14) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lang.localized("Total System Data", "Toplam Sistem Verileri"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(mainVM.formattedSystemDataSize)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.pink)
                            Text(lang.localized("Exact Apple Settings Match", "Apple Ayarları ile Birebir"))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    GlassCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lang.localized("Directly Cleanable", "Doğrudan Temizlenebilir"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(vm.formattedTotalScanned)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            Text(lang.localized("Simulator, DerivedData, Cache", "Simülatör, DerivedData, Cache"))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    GlassCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lang.localized("System & APFS Space", "Sistem & APFS Alanı"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(ByteCountFormatter.string(fromByteCount: max(0, mainVM.systemDataTotalBytes - vm.totalScannedBytes), countStyle: .file))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                            Text(lang.localized("Swap, Metadata, Snapshots", "Swap, Metadata, Snapshots"))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Explanatory Banner Card
                GlassCard {
                    HStack(spacing: 16) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.pink)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lang.localized(
                                "Why Does System Data Show \(mainVM.formattedSystemDataSize)?",
                                "Sistem Verileri Neden \(mainVM.formattedSystemDataSize) Görünüyor?"
                            ))
                            .font(.system(size: 13, weight: .bold))
                            
                            Text(lang.localized(
                                "macOS groups everything outside standard documents and applications (Xcode simulators, Homebrew packages, local APFS snapshots, swap caches, and hidden library temp files) into 'System Data'. You can safely move individual items to Trash or Permanently Delete them below.",
                                "Apple; belgeler, müzikler ve standart uygulamalar dışındaki her şeyi (Xcode simülatör diskleri, Homebrew kütüphaneleri, APFS yerel snapshot'ları, sanal bellek takas dosyaları ve gizli kütüphane önbelleklerini) 'Sistem Verileri' kategorisinde toplar. Aşağıdaki listeden dilediğiniz bileşeni Çöpe Gönderebilir veya Kalıcı Olarak silebilirsiniz."
                            ))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                
                if vm.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.large)
                        Text(lang.localized(
                            "Analyzing System Data (Simulators, Homebrew, Application Support)...",
                            "Sistem Verileri taranıyor (Simülatörler, Homebrew, Application Support)..."
                        ))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                } else if vm.items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "internaldrive.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.pink)
                        Text(lang.localized("Start scan to inspect System Data.", "Sistem Verilerini analiz etmek için taramayı başlatın."))
                            .font(.system(size: 14, weight: .medium))
                        Button(lang.localized("Start Scan", "Taramayı Başlat")) {
                            Task { await vm.analyze() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    // Items breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("\(lang.localized("Actionable System Locations", "Müdahale Edilebilir Sistem Alanları")) (\(vm.items.count) \(lang.localized("Sources", "Kaynak")))")
                                .font(.system(size: 15, weight: .bold))
                            Spacer()
                            Text("\(lang.localized("Total Inspected", "Toplam İncelenen")): \(vm.formattedTotalScanned)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.pink)
                        }
                        
                        VStack(spacing: 10) {
                            ForEach(vm.items) { item in
                                SystemDataRow(
                                    item: item,
                                    onTrash: {
                                        Task {
                                            await vm.deleteItem(item: item, mode: .trash)
                                            mainVM.refreshDiskSpace()
                                        }
                                    },
                                    onPermanentDelete: {
                                        itemToPermanentlyDelete = item
                                        showPermanentDeleteAlert = true
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            if vm.items.isEmpty {
                Task { await vm.analyze() }
            }
        }
        .alert(lang.localized("Permanent Deletion Confirmation", "Kalıcı Silme Onayı"), isPresented: $showPermanentDeleteAlert) {
            Button(lang.localized("Permanently Delete", "Tamamen Sil (Kalıcı)"), role: .destructive) {
                if let item = itemToPermanentlyDelete {
                    Task {
                        await vm.deleteItem(item: item, mode: .permanent)
                        mainVM.refreshDiskSpace()
                    }
                }
            }
            Button(lang.localized("Cancel", "Vazgeç"), role: .cancel) {}
        } message: {
            if let item = itemToPermanentlyDelete {
                Text(lang.localized(
                    "'\(item.title)' (\(item.formattedSize)) will be PERMANENTLY deleted from disk.\n\nThis cannot be undone. Do you wish to proceed?",
                    "'\(item.title)' (\(item.formattedSize)) doğrudan diskten KALICI OLARAK silinecektir.\n\nBu işlem geri alınamaz. Devam etmek istiyor musunuz?"
                ))
            } else {
                Text(lang.localized("This file/directory will be deleted permanently.", "Bu dosya/klasör kalıcı olarak silinecektir."))
            }
        }
        .alert(lang.localized("Notice", "Bilgi"), isPresented: $vm.showAlert) {
            Button(lang.localized("OK", "Tamam"), role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
    }
}
