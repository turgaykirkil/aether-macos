import SwiftUI

public struct LargeFilesView: View {
    @EnvironmentObject var mainVM: MainViewModel
    @StateObject private var vm = LargeFilesViewModel()
    @StateObject private var lang = LanguageManager.shared
    @State private var showPermanentDeleteAlert = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lang.localized("Large & Old Files Inspector", "Büyük & Eski Dosyalar"))
                            .font(.system(size: 22, weight: .bold))
                        Text(lang.localized(
                            "Locate heavy disk-consuming archives (.dmg, .iso), model weights, and old video media files instantly.",
                            "Disk alanınızı gizlice tüketen büyük arşivleri (.dmg, .iso), AI modellerini ve eski medya dosyalarını bulun"
                        ))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                // Filters Row
                HStack(spacing: 16) {
                    // Size Threshold Picker
                    Picker(lang.localized("Minimum Size:", "Minimum Boyut:"), selection: $vm.minSizeFilter) {
                        ForEach(vm.sizeThresholds, id: \.bytes) { item in
                            Text(item.label).tag(item.bytes)
                        }
                    }
                    .frame(width: 220)
                    
                    // Category Picker
                    Picker(lang.localized("Category:", "Kategori:"), selection: $vm.selectedCategory) {
                        ForEach(vm.categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .frame(width: 260)
                    
                    Spacer()
                    
                    Button(action: {
                        Task { await vm.scan() }
                    }) {
                        Label(
                            vm.isLoading ? lang.localized("Scanning...", "Taranıyor...") : lang.localized("Start Scan", "Taramayı Başlat"),
                            systemImage: "magnifyingglass"
                        )
                        .font(.system(size: 12, weight: .semibold))
                    }
                    .disabled(vm.isLoading)
                }
            }
            .padding(20)
            .background(Color.black.opacity(0.12))
            
            Divider()
            
            // Content
            if vm.isLoading {
                Spacer()
                ProgressView(lang.localized("Scanning large files via Spotlight & disk...", "Büyük dosyalar taranıyor..."))
                Spacer()
            } else if vm.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.indigo)
                    Text(lang.localized("Start scan to discover large files on disk.", "Taramayı başlatarak büyük dosyaları listeleyin."))
                        .font(.system(size: 14, weight: .medium))
                    Button(lang.localized("Start Scan", "Taramayı Başlat")) {
                        Task { await vm.scan() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    // Top action bar
                    HStack {
                        Button(action: {
                            let allSelected = vm.filteredItems.allSatisfy({ $0.isSelected })
                            vm.toggleSelectAll(select: !allSelected)
                        }) {
                            Text(vm.filteredItems.allSatisfy({ $0.isSelected }) ? lang.localized("Deselect All", "Seçimi Kaldır") : lang.localized("Select Displayed", "Görüntülenenleri Seç"))
                                .font(.system(size: 12))
                        }
                        
                        Spacer()
                        
                        Text("\(lang.localized("Selected:", "Seçilen:")) \(vm.formattedSelectedSize)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.indigo)
                        
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
                                            .foregroundColor(item.isSelected ? .indigo : .gray)
                                            .font(.system(size: 16))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(.indigo)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.system(size: 13, weight: .medium))
                                            .lineLimit(1)
                                        Text(item.path)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        vm.revealInFinder(item)
                                    }) {
                                        Image(systemName: "arrow.right.circle")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Finder'da Göster")
                                    
                                    Text(item.category)
                                        .font(.system(size: 10))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.indigo.opacity(0.12))
                                        .cornerRadius(4)
                                    
                                    Text(item.formattedSize)
                                        .font(.system(size: 12, weight: .bold))
                                        .frame(minWidth: 75, alignment: .trailing)
                                }
                                .padding(10)
                                .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                                .cornerRadius(8)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .onAppear {
            if vm.items.isEmpty {
                Task { await vm.scan() }
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
                "Selected \(vm.formattedSelectedSize) of large files will be PERMANENTLY deleted from disk.\n\nAre you sure?",
                "Seçilen \(vm.formattedSelectedSize) boyutundaki büyük dosyalar diskten KALICI OLARAK silinecektir.\n\nBu işlem geri alınamaz. Emin misiniz?"
            ))
        }
        .alert(lang.localized("Completed", "İşlem Tamamlandı"), isPresented: $vm.showResultSheet) {
            Button(lang.localized("OK", "Tamam"), role: .cancel) {}
        } message: {
            Text("\(ByteCountFormatter.string(fromByteCount: vm.lastFreedBytes, countStyle: .file)) \(lang.localized("freed successfully.", "alan başarıyla boşaltıldı."))")
        }
    }
}
