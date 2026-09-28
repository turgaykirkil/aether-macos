import SwiftUI

public struct OrphanedLeftoversView: View {
    @EnvironmentObject var mainVM: MainViewModel
    @StateObject private var vm = AppUninstallerViewModel()
    @State private var showBatchPermanentDeleteAlert = false
    @State private var singleItemToPermanentlyDelete: CleanItem? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Silinmiş Uygulama Artıkları (Sahipsiz Dosyalar)")
                                .font(.system(size: 22, weight: .bold))
                            
                            if !vm.orphanedItems.isEmpty {
                                Text("\(vm.orphanedItems.count) Kalıntı / \(vm.formattedTotalOrphanSize)")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundColor(.orange)
                                    .cornerRadius(6)
                            }
                        }
                        
                        Text("Daha önce çöp sepetine atılarak silinen ancak ~/Library altında unutulmuş Application Support, Caches ve SavedState kalıntılarını tespit eder.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    HStack(spacing: 10) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Kalıntı ara...", text: $vm.orphanSearchText)
                                .textFieldStyle(.plain)
                        }
                        .padding(7)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                        .frame(width: 180)
                        
                        Button(action: {
                            Task { await vm.loadApps() }
                        }) {
                            Label(vm.isScanningOrphans ? "Taranıyor..." : "Yeniden Tara", systemImage: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .disabled(vm.isScanningOrphans)
                    }
                }
            }
            .padding(20)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Content
            if vm.isScanningOrphans || vm.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.large)
                    Text("Library dizinleri taranıyor ve sahipsiz uygulama kalıntıları tespit ediliyor...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.orphanedItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.green)
                    Text("Sisteminizde silinmiş uygulama artığı bulunamadı.")
                        .font(.system(size: 14, weight: .medium))
                    Button("Yeniden Tara") {
                        Task { await vm.loadApps() }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    // Top Action Bar
                    HStack {
                        Button(action: {
                            let allSelected = vm.filteredOrphans.allSatisfy({ $0.isSelected })
                            vm.toggleAllOrphans(select: !allSelected)
                        }) {
                            Text(vm.filteredOrphans.allSatisfy({ $0.isSelected }) ? "Seçimi Kaldır" : "Tümünü Seç")
                                .font(.system(size: 12))
                        }
                        
                        Spacer()
                        
                        Text("Seçilen: \(vm.formattedSelectedOrphanSize)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.orange)
                        
                        // Dual action buttons: Çöpe Gönder & Tamamen Sil
                        HStack(spacing: 8) {
                            Button(action: {
                                Task {
                                    await vm.cleanSelectedOrphans(mode: .trash)
                                    mainVM.refreshDiskSpace()
                                }
                            }) {
                                Label("Seçilenleri Çöpe Taşı", systemImage: "trash")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                            .disabled(vm.selectedOrphanBytes == 0)
                            
                            Button(action: {
                                showBatchPermanentDeleteAlert = true
                            }) {
                                Label("Seçilenleri Tamamen Sil", systemImage: "flame.fill")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .disabled(vm.selectedOrphanBytes == 0)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                    
                    Divider()
                    
                    // List
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(vm.filteredOrphans) { item in
                                HStack(spacing: 12) {
                                    Button(action: {
                                        if let idx = vm.orphanedItems.firstIndex(where: { $0.id == item.id }) {
                                            vm.orphanedItems[idx].isSelected.toggle()
                                        }
                                    }) {
                                        Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(item.isSelected ? .orange : .gray)
                                            .font(.system(size: 16))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                                        .foregroundColor(.orange.opacity(0.8))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 8) {
                                            Text(item.name)
                                                .font(.system(size: 13, weight: .semibold))
                                            
                                            Text(item.category)
                                                .font(.system(size: 10, weight: .medium))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.12))
                                                .foregroundColor(.orange)
                                                .cornerRadius(4)
                                        }
                                        
                                        Text(item.path)
                                            .font(.system(size: 10, design: .monospaced))
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
                                    
                                    Text(item.formattedSize)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .frame(minWidth: 70, alignment: .trailing)
                                    
                                    // Individual Action Buttons: Çöp & Kalıcı
                                    HStack(spacing: 6) {
                                        Button(action: {
                                            Task {
                                                await vm.cleanSingleOrphan(item: item, mode: .trash)
                                                mainVM.refreshDiskSpace()
                                            }
                                        }) {
                                            HStack(spacing: 3) {
                                                Image(systemName: "trash")
                                                Text("Çöp")
                                            }
                                            .font(.system(size: 11))
                                        }
                                        .buttonStyle(.bordered)
                                        .help("Çöpe Gönder")
                                        
                                        Button(action: {
                                            singleItemToPermanentlyDelete = item
                                        }) {
                                            HStack(spacing: 3) {
                                                Image(systemName: "flame.fill")
                                                Text("Sil")
                                            }
                                            .font(.system(size: 11, weight: .semibold))
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.red)
                                        .help("Kalıcı Olarak Sil")
                                    }
                                }
                                .padding(12)
                                .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                                .cornerRadius(10)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .onAppear {
            if vm.orphanedItems.isEmpty {
                Task { await vm.loadApps() }
            }
        }
        .alert("Toplu Kalıcı Silme Onayı", isPresented: $showBatchPermanentDeleteAlert) {
            Button("Seçilenleri Tamamen Sil (\(vm.formattedSelectedOrphanSize))", role: .destructive) {
                Task {
                    await vm.cleanSelectedOrphans(mode: .permanent)
                    mainVM.refreshDiskSpace()
                }
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Seçilen \(vm.formattedSelectedOrphanSize) boyutundaki kalıntılar diskten KALICI OLARAK silinecektir.\n\nBu işlem geri alınamaz. Emin misiniz?")
        }
        .alert("Kalıcı Silme Onayı", isPresented: Binding(
            get: { singleItemToPermanentlyDelete != nil },
            set: { if !$0 { singleItemToPermanentlyDelete = nil } }
        )) {
            Button("Tamamen Sil", role: .destructive) {
                if let item = singleItemToPermanentlyDelete {
                    Task {
                        await vm.cleanSingleOrphan(item: item, mode: .permanent)
                        mainVM.refreshDiskSpace()
                    }
                }
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            if let item = singleItemToPermanentlyDelete {
                Text("'\(item.name)' (\(item.formattedSize)) kalıntısı diskten KALICI OLARAK silinecektir.\n\nEmin misiniz?")
            }
        }
        .alert("İşlem Tamamlandı", isPresented: $vm.showSuccessAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
    }
}
