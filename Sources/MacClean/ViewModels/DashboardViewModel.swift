import Foundation
import SwiftUI
import Combine

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var isScanning: Bool = false
    @Published public var isCleaning: Bool = false
    @Published public var systemJunkItems: [CleanItem] = []
    @Published public var developerItems: [CleanItem] = []
    @Published public var scanCompleted: Bool = false
    @Published public var statusText: String = "Sistem taranmaya hazır."
    @Published public var freedBytesLastClean: Int64 = 0
    @Published public var showSuccessSheet: Bool = false
    
    public init() {}
    
    public var totalCleanableBytes: Int64 {
        let systemTotal = systemJunkItems.filter({ $0.isSelected }).reduce(0) { $0 + $1.size }
        let devTotal = developerItems.filter({ $0.isSelected }).reduce(0) { $0 + $1.size }
        return systemTotal + devTotal
    }
    
    public var formattedTotalCleanable: String {
        ByteCountFormatter.string(fromByteCount: totalCleanableBytes, countStyle: .file)
    }
    
    public func startSmartScan() async {
        isScanning = true
        scanCompleted = false
        statusText = "Sistem önbellekleri ve loglar taranıyor..."
        
        let systemItems = await SystemCleanerService.shared.scanSystemJunk()
        self.systemJunkItems = systemItems
        
        statusText = "Geliştirici ve AI modelleri taranıyor..."
        let devItems = await DeveloperCleanerService.shared.scanDeveloperAndAIJunk()
        self.developerItems = devItems
        
        isScanning = false
        scanCompleted = true
        statusText = "Akıllı tarama tamamlandı. Toplam \(formattedTotalCleanable) temizlenebilir alan bulundu."
    }
    
    public func cleanSelectedItems(mode: DeletionMode) async -> (freed: Int64, success: Int, failed: Int) {
        isCleaning = true
        statusText = "Seçilen öğeler temizleniyor..."
        
        let selected = (systemJunkItems + developerItems).filter({ $0.isSelected })
        let result = DeletionService.shared.deleteItems(selected, mode: mode)
        
        self.freedBytesLastClean = result.freedBytes
        
        // Listeleri güncelle
        let remainingSystem = systemJunkItems.filter { item in
            !selected.contains(where: { $0.id == item.id })
        }
        let remainingDev = developerItems.filter { item in
            !selected.contains(where: { $0.id == item.id })
        }
        
        self.systemJunkItems = remainingSystem
        self.developerItems = remainingDev
        
        isCleaning = false
        showSuccessSheet = true
        statusText = "\(ByteCountFormatter.string(fromByteCount: result.freedBytes, countStyle: .file)) alan başarıyla boşaltıldı."
        
        return (result.freedBytes, result.successCount, result.failedCount)
    }
}
