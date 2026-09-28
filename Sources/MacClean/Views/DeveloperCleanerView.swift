import SwiftUI

public struct DeveloperCleanerView: View {
    @EnvironmentObject var mainVM: MainViewModel
    @StateObject private var vm = DeveloperCleanViewModel()
    @StateObject private var lang = LanguageManager.shared
    @State private var showPermanentDeleteAlert = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(lang.localized("AI & Developer Artifact Cleaner", "AI & Geliştirici Temizliği"))
                                .font(.system(size: 22, weight: .bold))
                            
                            HStack(spacing: 4) {
                                Image(systemName: "shield.fill")
                                Text(lang.localized("Active Workspace Protected", "Aktif Proje Korumalı"))
                            }
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(5)
                        }
                        
                        Text(lang.localized(
                            "Running processes or repositories modified within the last 7 days are shielded and locked.",
                            "Çalışan veya son 7 günde üzerinde çalışılan aktif projeler kalkanla kilitlenir ve korunur."
                        ))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await vm.scan()
                        }
                    }) {
                        Label(
                            vm.isLoading ? lang.localized("Scanning...", "Taranıyor...") : lang.localized("Re-Scan", "Yeniden Tara"),
                            systemImage: "arrow.clockwise"
                        )
                        .font(.system(size: 12, weight: .semibold))
                    }
                    .disabled(vm.isLoading)
                }
                
                // Filters Bar
                HStack(spacing: 10) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(vm.filterCategories, id: \.self) { cat in
                                Button(action: {
                                    vm.selectedFilter = cat
                                }) {
                                    Text(cat)
                                        .font(.system(size: 12, weight: vm.selectedFilter == cat ? .semibold : .regular))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(vm.selectedFilter == cat ? Color.purple : Color.secondary.opacity(0.12))
                                        .foregroundColor(vm.selectedFilter == cat ? .white : .primary)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Content
            if vm.isLoading {
                Spacer()
                ProgressView("Geliştirici ve AI dosyaları analiz ediliyor (Aktif projeler taranıyor)...")
                Spacer()
            } else if vm.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("Geliştirici önbellekleri ve AI modelleri temiz.")
                        .font(.system(size: 14, weight: .medium))
                    Button("Taramayı Başlat") {
                        Task { await vm.scan() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    // Top stats bar
                    HStack {
                        Button(action: {
                            let allSelected = vm.filteredItems.allSatisfy({ $0.isSelected })
                            vm.toggleAll(select: !allSelected)
                        }) {
                            Text(vm.filteredItems.allSatisfy({ $0.isSelected }) ? lang.localized("Deselect All", "Tümünün Seçimini Kaldır") : lang.localized("Select Safe Items", "Güvenli Öğeleri Seç"))
                                .font(.system(size: 12))
                        }
                        
                        Spacer()
                        
                        Text("\(lang.localized("Selected:", "Seçilen Alan:")) \(vm.formattedSelectedSize)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.purple)
                        
                        // Dual action buttons: Çöpe Taşı & Tamamen Sil
                        HStack(spacing: 8) {
                            Button(action: {
                                Task {
                                    await vm.cleanSelected(mode: .trash)
                                    mainVM.refreshDiskSpace()
                                }
                            }) {
                                Label(lang.localized("Move to Trash", "Çöpe Taşı"), systemImage: "trash")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                            .disabled(vm.totalSelectedBytes == 0 || vm.isCleaning)
                            
                            Button(action: {
                                showPermanentDeleteAlert = true
                            }) {
                                Label(lang.localized("Delete Forever", "Tamamen Sil"), systemImage: "flame.fill")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .disabled(vm.totalSelectedBytes == 0 || vm.isCleaning)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.12))
                    
                    Divider()
                    
                    // List
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(vm.filteredItems) { item in
                                HStack(spacing: 12) {
                                    Button(action: {
                                        if let idx = vm.items.firstIndex(where: { $0.id == item.id }) {
                                            vm.items[idx].isSelected.toggle()
                                        }
                                    }) {
                                        Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(item.isSelected ? .purple : .gray)
                                            .font(.system(size: 16))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                                        .foregroundColor(item.safetyLevel == .protectedActive ? .blue : .purple)
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 8) {
                                            Text(item.name)
                                                .font(.system(size: 13, weight: .semibold))
                                            
                                            SafetyBadgeView(safety: item.safetyLevel)
                                        }
                                        
                                        Text(item.detail)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(item.category)
                                        .font(.system(size: 10, weight: .medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.purple.opacity(0.12))
                                        .cornerRadius(4)
                                    
                                    Text(item.formattedSize)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .frame(minWidth: 70, alignment: .trailing)
                                }
                                .padding(12)
                                .background(Color.black.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(item.safetyLevel == .protectedActive ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                                 )
                                .cornerRadius(10)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .onAppear {
            if vm.items.isEmpty {
                Task {
                    await vm.scan()
                }
            }
        }
        .alert(lang.localized("Permanent Deletion Confirmation", "Kalıcı Silme Onayı"), isPresented: $showPermanentDeleteAlert) {
            Button("\(lang.localized("Delete Forever", "Tamamen Sil")) (\(vm.formattedSelectedSize))", role: .destructive) {
                Task {
                    await vm.cleanSelected(mode: .permanent)
                    mainVM.refreshDiskSpace()
                }
            }
            Button(lang.localized("Cancel", "Vazgeç"), role: .cancel) {}
        } message: {
            Text(lang.localized(
                "Selected \(vm.formattedSelectedSize) of developer and AI artifacts will be PERMANENTLY deleted from disk.\n\nAre you sure?",
                "Seçilen \(vm.formattedSelectedSize) boyutundaki geliştirici ve AI dosyaları diskten KALICI OLARAK silinecektir.\n\nBu işlem geri alınamaz. Emin misiniz?"
            ))
        }
        .alert(lang.localized("Completed", "Temizlik Tamamlandı"), isPresented: $vm.showResultSheet) {
            Button(lang.localized("OK", "Tamam"), role: .cancel) {}
        } message: {
            Text("\(ByteCountFormatter.string(fromByteCount: vm.lastFreedBytes, countStyle: .file)) \(lang.localized("freed successfully.", "alan başarıyla boşaltıldı."))")
        }
    }
}
