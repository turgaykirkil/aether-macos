import Foundation
import SwiftUI
import AppKit
import Combine

public enum AppUninstallerTab: String, CaseIterable, Identifiable {
    case installedApps = "installedApps"
    case orphanedLeftovers = "orphanedLeftovers"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .installedApps:
            return "Yüklü Uygulamalar"
        case .orphanedLeftovers:
            return "Silinmiş Uygulama Artıkları"
        }
    }
    
    public var icon: String {
        switch self {
        case .installedApps:
            return "app.badge.checkmark"
        case .orphanedLeftovers:
            return "ghost.fill"
        }
    }
}

@MainActor
public final class AppUninstallerViewModel: ObservableObject {
    @Published public var selectedTab: AppUninstallerTab = .installedApps
    
    // Yüklü Uygulamalar
    @Published public var installedApps: [AppBundleItem] = []
    @Published public var selectedApp: AppBundleItem? = nil
    @Published public var isLoading: Bool = false
    @Published public var searchText: String = ""
    @Published public var isUninstalling: Bool = false
    
    // Silinmiş Uygulama Artıkları (Orphans)
    @Published public var orphanedItems: [CleanItem] = []
    @Published public var isScanningOrphans: Bool = false
    @Published public var orphanSearchText: String = ""
    
    // Bildirim ve Durum
    @Published public var statusMessage: String = ""
    @Published public var showSuccessAlert: Bool = false
    @Published public var alertMessage: String = ""
    @Published public var lastUninstalledName: String = ""
    @Published public var lastFreedBytes: Int64 = 0
    
    public init() {}
    
    public var filteredApps: [AppBundleItem] {
        if searchText.isEmpty {
            return installedApps
        } else {
            return installedApps.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    public var filteredOrphans: [CleanItem] {
        if orphanSearchText.isEmpty {
            return orphanedItems
        } else {
            return orphanedItems.filter {
                $0.name.localizedCaseInsensitiveContains(orphanSearchText) ||
                $0.category.localizedCaseInsensitiveContains(orphanSearchText) ||
                $0.path.localizedCaseInsensitiveContains(orphanSearchText)
            }
        }
    }
    
    public var totalOrphanBytes: Int64 {
        orphanedItems.reduce(0) { $0 + $1.size }
    }
    
    public var formattedTotalOrphanSize: String {
        ByteCountFormatter.string(fromByteCount: totalOrphanBytes, countStyle: .file)
    }
    
    public var selectedOrphanBytes: Int64 {
        filteredOrphans.filter({ $0.isSelected }).reduce(0) { $0 + $1.size }
    }
    
    public var formattedSelectedOrphanSize: String {
        ByteCountFormatter.string(fromByteCount: selectedOrphanBytes, countStyle: .file)
    }
    
    public func loadApps() async {
        isLoading = true
        statusMessage = "Yüklü uygulamalar taranıyor..."
        let apps = await AppUninstallerService.shared.scanInstalledApplications()
        self.installedApps = apps
        if self.selectedApp == nil && !apps.isEmpty {
            self.selectedApp = apps.first
        }
        self.isLoading = false
        
        // Otomatik olarak yetim artıkları da tara
        await scanOrphans()
    }
    
    public func scanOrphans() async {
        isScanningOrphans = true
        let orphans = await OrphanedAppService.shared.scanOrphanedItems(installedApps: self.installedApps)
        self.orphanedItems = orphans
        self.isScanningOrphans = false
    }
    
    public func handleDroppedAppURL(_ url: URL) {
        guard url.pathExtension.lowercased() == "app" else { return }
        if let inspected = AppUninstallerService.shared.inspectAppBundle(at: url) {
            if let index = installedApps.firstIndex(where: { $0.appUrl.path == url.path }) {
                self.selectedApp = installedApps[index]
            } else {
                self.installedApps.insert(inspected, at: 0)
                self.selectedApp = inspected
            }
        }
    }
    
    public func uninstallSelectedApp(mode: DeletionMode) async {
        guard let app = selectedApp else { return }
        isUninstalling = true
        
        var itemsToDelete: [CleanItem] = app.relatedItems.filter({ $0.isSelected })
        itemsToDelete.append(CleanItem(
            name: app.name,
            path: app.appUrl.path,
            size: app.appSize,
            category: "Uygulama Paketi (.app)",
            detail: app.appUrl.path,
            isDirectory: true,
            isSelected: true
        ))
        
        let result = DeletionService.shared.deleteItems(itemsToDelete, mode: mode)
        
        self.lastUninstalledName = app.name
        self.lastFreedBytes = result.freedBytes
        
        self.installedApps.removeAll(where: { $0.id == app.id })
        self.selectedApp = self.installedApps.first
        
        self.isUninstalling = false
        self.alertMessage = "\(app.name) ve tüm ilişkili kalıntıları başarıyla kaldırıldı. (\(ByteCountFormatter.string(fromByteCount: result.freedBytes, countStyle: .file)) alan açıldı)"
        self.showSuccessAlert = true
    }
    
    public func cleanSelectedOrphans(mode: DeletionMode) async {
        let selected = filteredOrphans.filter({ $0.isSelected })
        guard !selected.isEmpty else { return }
        
        isScanningOrphans = true
        let result = DeletionService.shared.deleteItems(selected, mode: mode)
        
        self.orphanedItems.removeAll(where: { item in selected.contains(where: { $0.id == item.id }) })
        self.isScanningOrphans = false
        
        self.alertMessage = "\(result.successCount) adet silinmiş uygulama artığı temizlendi. (\(ByteCountFormatter.string(fromByteCount: result.freedBytes, countStyle: .file)) alan boşaltıldı)"
        self.showSuccessAlert = true
    }
    
    public func cleanSingleOrphan(item: CleanItem, mode: DeletionMode) async {
        do {
            try DeletionService.shared.deleteItem(at: item.path, mode: mode)
            self.orphanedItems.removeAll(where: { $0.id == item.id })
            self.alertMessage = "\(item.name) başarıyla temizlendi."
            self.showSuccessAlert = true
        } catch {
            self.alertMessage = "Silme hatası: \(error.localizedDescription)"
            self.showSuccessAlert = true
        }
    }
    
    public func toggleAllOrphans(select: Bool) {
        let ids = Set(filteredOrphans.map { $0.id })
        for i in 0..<orphanedItems.count {
            if ids.contains(orphanedItems[i].id) {
                orphanedItems[i].isSelected = select
            }
        }
    }
    
    public func revealInFinder(_ item: CleanItem) {
        let url = URL(fileURLWithPath: item.path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
