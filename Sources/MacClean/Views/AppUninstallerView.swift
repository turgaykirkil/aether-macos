import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct AppUninstallerView: View {
    @EnvironmentObject var mainVM: MainViewModel
    @StateObject private var vm = AppUninstallerViewModel()
    @StateObject private var lang = LanguageManager.shared
    @State private var isDropTargeted = false
    @State private var showAppPermanentDeleteAlert = false
    @State private var showOrphanBatchPermanentDeleteAlert = false
    @State private var singleOrphanToPermanentlyDelete: CleanItem? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Segmented Tab Picker
            HStack {
                Picker("", selection: $vm.selectedTab) {
                    Label("\(lang.localized("Installed Applications", "Yüklü Uygulamalar")) (\(vm.installedApps.count))", systemImage: "app.badge.checkmark")
                        .tag(AppUninstallerTab.installedApps)
                    
                    Label("\(lang.localized("Orphaned Leftovers", "Silinmiş Uygulama Artıkları")) (\(vm.orphanedItems.count))", systemImage: "ghost.fill")
                        .tag(AppUninstallerTab.orphanedLeftovers)
                }
                .pickerStyle(.segmented)
                .frame(width: 440)
                
                Spacer()
                
                if vm.selectedTab == .orphanedLeftovers {
                    Button(action: {
                        Task { await vm.scanOrphans() }
                    }) {
                        Label(
                            vm.isScanningOrphans ? lang.localized("Scanning...", "Taranıyor...") : lang.localized("Re-Scan Leftovers", "Artıkları Yeniden Tara"),
                            systemImage: "arrow.clockwise"
                        )
                        .font(.system(size: 12))
                    }
                    .disabled(vm.isScanningOrphans)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.15))
            
            Divider()
            
            // Tab Content Router
            Group {
                switch vm.selectedTab {
                case .installedApps:
                    installedAppsView
                case .orphanedLeftovers:
                    orphanedLeftoversView
                }
            }
        }
        .onAppear {
            if vm.installedApps.isEmpty {
                Task {
                    await vm.loadApps()
                }
            }
        }
        // Alerts
        .alert(lang.localized("Permanent Uninstall Confirmation", "Kalıcı Kaldırma Onayı"), isPresented: $showAppPermanentDeleteAlert) {
            Button(lang.localized("Delete Forever", "Tamamen Sil"), role: .destructive) {
                Task {
                    await vm.uninstallSelectedApp(mode: .permanent)
                    mainVM.refreshDiskSpace()
                }
            }
            Button(lang.localized("Cancel", "Vazgeç"), role: .cancel) {}
        } message: {
            Text(lang.localized(
                "\(vm.selectedApp?.name ?? "") and all selected Library leftovers will be PERMANENTLY deleted from disk.\n\nThis cannot be undone. Are you sure?",
                "\(vm.selectedApp?.name ?? "") uygulaması ve seçilen tüm Library kalıntıları diskten KALICI OLARAK silinecektir.\n\nBu işlem geri alınamaz. Emin misiniz?"
            ))
        }
        .alert(lang.localized("Batch Deletion Confirmation", "Toplu Kalıcı Silme Onayı"), isPresented: $showOrphanBatchPermanentDeleteAlert) {
            Button("\(lang.localized("Delete Forever", "Seçilenleri Tamamen Sil")) (\(vm.formattedSelectedOrphanSize))", role: .destructive) {
                Task {
                    await vm.cleanSelectedOrphans(mode: .permanent)
                    mainVM.refreshDiskSpace()
                }
            }
            Button(lang.localized("Cancel", "Vazgeç"), role: .cancel) {}
        } message: {
            Text(lang.localized(
                "Selected \(vm.formattedSelectedOrphanSize) of leftover files will be PERMANENTLY deleted from disk.\n\nAre you sure?",
                "Seçilen \(vm.formattedSelectedOrphanSize) boyutundaki silinmiş uygulama kalıntıları diskten KALICI OLARAK silinecektir.\n\nBu işlem geri alınamaz. Emin misiniz?"
            ))
        }
        .alert(lang.localized("Permanent Deletion", "Kalıcı Silme Onayı"), isPresented: Binding(
            get: { singleOrphanToPermanentlyDelete != nil },
            set: { if !$0 { singleOrphanToPermanentlyDelete = nil } }
        )) {
            Button(lang.localized("Delete Forever", "Tamamen Sil"), role: .destructive) {
                if let item = singleOrphanToPermanentlyDelete {
                    Task {
                        await vm.cleanSingleOrphan(item: item, mode: .permanent)
                        mainVM.refreshDiskSpace()
                    }
                }
            }
            Button(lang.localized("Cancel", "Vazgeç"), role: .cancel) {}
        } message: {
            if let item = singleOrphanToPermanentlyDelete {
                Text(lang.localized(
                    "'\(item.name)' (\(item.formattedSize)) will be PERMANENTLY deleted from disk.\n\nAre you sure?",
                    "'\(item.name)' (\(item.formattedSize)) kalıntısı diskten KALICI OLARAK silinecektir.\n\nEmin misiniz?"
                ))
            }
        }
        .alert(lang.localized("Completed", "İşlem Tamamlandı"), isPresented: $vm.showSuccessAlert) {
            Button(lang.localized("OK", "Tamam"), role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
    }
    
    // MARK: - 1. Yüklü Uygulamalar Görünümü
    private var installedAppsView: some View {
        HSplitView {
            // Left App List
            VStack(spacing: 0) {
                // Search and header
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField(lang.localized("Search apps...", "Uygulama ara..."), text: $vm.searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.12))
                    .cornerRadius(8)
                    
                    // Drag & Drop Hint Banner
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc.fill")
                            .foregroundColor(.orange)
                        Text(lang.localized("Drag & drop a .app file here", "Bir .app dosyasını buraya sürükleyebilirsiniz"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(6)
                    .background(isDropTargeted ? Color.orange.opacity(0.2) : Color.secondary.opacity(0.08))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isDropTargeted ? Color.orange : Color.clear, lineWidth: 1)
                    )
                }
                .padding(12)
                
                Divider()
                
                if vm.isLoading {
                    Spacer()
                    ProgressView(lang.localized("Scanning applications...", "Uygulamalar taranıyor..."))
                    Spacer()
                } else {
                    List(selection: $vm.selectedApp) {
                        ForEach(vm.filteredApps) { app in
                            HStack(spacing: 10) {
                                Image(nsImage: app.appIcon)
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(1)
                                    Text("v\(app.version)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(app.formattedTotalSize)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            .tag(app)
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .frame(minWidth: 260, idealWidth: 300, maxWidth: 380)
            
            // Right App Detail & Leftovers
            if let app = vm.selectedApp {
                VStack(spacing: 0) {
                    // App Header
                    HStack(spacing: 16) {
                        Image(nsImage: app.appIcon)
                            .resizable()
                            .frame(width: 54, height: 54)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(app.name)
                                .font(.system(size: 18, weight: .bold))
                            Text(app.bundleIdentifier.isEmpty ? app.appUrl.path : app.bundleIdentifier)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            HStack(spacing: 12) {
                                Text("\(lang.localized("App:", "Uygulama:")) \(app.formattedAppSize)")
                                    .font(.system(size: 11, weight: .medium))
                                Text("\(lang.localized("Total:", "Toplam Alan:")) \(app.formattedTotalSize)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Spacer()
                        
                        // Dual action buttons: Çöpe Gönder & Tamamen Sil
                        HStack(spacing: 8) {
                            Button(action: {
                                Task {
                                    await vm.uninstallSelectedApp(mode: .trash)
                                    mainVM.refreshDiskSpace()
                                }
                            }) {
                                Label(lang.localized("Move to Trash", "Çöpe Gönder"), systemImage: "trash")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                            .disabled(vm.isUninstalling)
                            .help(lang.localized("Moves app and leftovers to macOS Trash (Recoverable)", "Uygulamayı ve kalıntıları macOS Çöp Sepeti'ne atar (Geri alınabilir)"))
                            
                            Button(action: {
                                showAppPermanentDeleteAlert = true
                            }) {
                                Label(lang.localized("Delete Forever", "Tamamen Sil"), systemImage: "flame.fill")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .disabled(vm.isUninstalling)
                            .help(lang.localized("Permanently removes app and all leftovers from disk", "Uygulamayı ve tüm kalıntıları diskten kalıcı olarak siler"))
                        }
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.12))
                    
                    Divider()
                    
                    // Leftover Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("İlişkili Dosyalar & Kalıntılar (\(app.relatedItems.count + 1) Öğe)")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                // Ana Uygulama Dosyası
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.orange)
                                    Image(systemName: "app.dashed")
                                        .foregroundColor(.secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(app.name).app")
                                            .font(.system(size: 12, weight: .medium))
                                        Text(app.appUrl.path)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text("Ana Uygulama")
                                        .font(.system(size: 10))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.12))
                                        .cornerRadius(4)
                                    Text(app.formattedAppSize)
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .padding(10)
                                .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                                .cornerRadius(8)
                                
                                if app.relatedItems.isEmpty {
                                    VStack(spacing: 6) {
                                        Image(systemName: "checkmark.shield")
                                            .font(.system(size: 24))
                                            .foregroundColor(.green)
                                        Text("Bu uygulama için Library dizininde ekstra kalıntı bulunamadı.")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 30)
                                } else {
                                    ForEach(app.relatedItems) { item in
                                        HStack(spacing: 10) {
                                            Button(action: {
                                                if let appIdx = vm.installedApps.firstIndex(where: { $0.id == app.id }),
                                                   let itemIdx = vm.installedApps[appIdx].relatedItems.firstIndex(where: { $0.id == item.id }) {
                                                    vm.installedApps[appIdx].relatedItems[itemIdx].isSelected.toggle()
                                                    vm.selectedApp = vm.installedApps[appIdx]
                                                }
                                            }) {
                                                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(item.isSelected ? .orange : .gray)
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                                                .foregroundColor(.secondary)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name)
                                                    .font(.system(size: 12, weight: .medium))
                                                Text(item.detail)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                            Spacer()
                                            
                                            Text(item.category)
                                                .font(.system(size: 10))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.secondary.opacity(0.12))
                                                .cornerRadius(4)
                                            
                                            Text(item.formattedSize)
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                        .padding(10)
                                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "app.badge.checkmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Kaldırmak istediğiniz uygulamayı sol listeden seçin veya buraya sürükleyin.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async {
                        vm.handleDroppedAppURL(url)
                    }
                }
            }
            return true
        }
    }
    
    // MARK: - 2. Silinmiş Uygulama Artıkları (Orphaned Leftovers) Görünümü
    private var orphanedLeftoversView: some View {
        VStack(spacing: 0) {
            // Header Info Card
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Silinmiş Uygulama Kalıntıları (Orphaned Leftovers)")
                                .font(.system(size: 20, weight: .bold))
                            
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
                        
                        Text("Daha önce çöp sepetine atılarak silinen ancak ~/Library altında unutulmuş Application Support, Caches ve SavedState artıklarını tespit eder.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Kalıntı ara...", text: $vm.orphanSearchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(7)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .frame(width: 200)
                }
            }
            .padding(20)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
            
            Divider()
            
            if vm.isScanningOrphans {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.large)
                    Text("Silinmiş uygulama kalıntıları taranıyor...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.orphanedItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.green)
                    Text("Tebrikler! Sisteminizde silinmiş uygulama artığı bulunamadı.")
                        .font(.system(size: 14, weight: .medium))
                    Button("Yeniden Tara") {
                        Task { await vm.scanOrphans() }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Top Batch Action Bar
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
                    
                    // Batch Action Buttons
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
                            showOrphanBatchPermanentDeleteAlert = true
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
                
                // Orphaned Items List
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
                                
                                // Individual actions: Çöp & Kalıcı
                                HStack(spacing: 4) {
                                    Button(action: {
                                        Task {
                                            await vm.cleanSingleOrphan(item: item, mode: .trash)
                                            mainVM.refreshDiskSpace()
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Çöpe Gönder")
                                    
                                    Button(action: {
                                        singleOrphanToPermanentlyDelete = item
                                    }) {
                                        Image(systemName: "flame.fill")
                                            .foregroundColor(.red.opacity(0.8))
                                    }
                                    .buttonStyle(.plain)
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
}
