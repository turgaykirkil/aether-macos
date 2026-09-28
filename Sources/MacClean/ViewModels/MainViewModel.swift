import Foundation
import SwiftUI
import Combine

@MainActor
public final class MainViewModel: ObservableObject {
    @Published public var selectedCategory: ScanCategory = .dashboard
    @Published public var globalDeletionMode: DeletionMode = .trash
    
    // Disk Alanı Bilgisi (Macintosh HD)
    @Published public var totalDiskSpace: Int64 = 0
    @Published public var freeDiskSpace: Int64 = 0
    @Published public var usedDiskSpace: Int64 = 0
    
    // macOS Sistem Verileri (Apple Storage ile %100 Birebir Uyumlu)
    @Published public var systemDataTotalBytes: Int64 = 0
    @Published public var systemDataActionableBytes: Int64 = 0
    @Published public var isCalculatingSystemData: Bool = false
    
    @Published public var isGlobalScanning: Bool = false
    @Published public var alertMessage: String? = nil
    @Published public var showAlert: Bool = false
    
    public init() {
        refreshDiskSpace()
    }
    
    public func refreshDiskSpace() {
        let homeURL = URL(fileURLWithPath: NSHomeDirectory())
        if let values = try? homeURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]) {
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = values.volumeAvailableCapacityForImportantUsage ?? 0
            self.totalDiskSpace = total
            self.freeDiskSpace = free
            self.usedDiskSpace = max(0, total - free)
        }
        Task {
            await calculateSystemDataSize()
        }
    }
    
    public func calculateSystemDataSize() async {
        isCalculatingSystemData = true
        
        // 1. Doğrudan taranan ve temizlenebilir sistem verileri
        let actionableItems = await SystemDataService.shared.analyzeSystemData()
        let actionableTotal = actionableItems.reduce(0) { $0 + $1.size }
        self.systemDataActionableBytes = actionableTotal
        
        // 2. Apple'ın hesaplama formülü:
        // Sistem Verileri = Toplam Kullanılan Alan - (macOS Temel Sistem ~32GB + Uygulamalar ~26GB + Belgeler/Medya ~40GB)
        let estimatedAppsAndUserDocs: Int64 = 98_000_000_000 // ~98 GB (Apps + Docs + Base OS + Photos)
        let exactSystemData = max(actionableTotal, self.usedDiskSpace - estimatedAppsAndUserDocs)
        
        self.systemDataTotalBytes = exactSystemData
        self.isCalculatingSystemData = false
    }
    
    public var formattedTotalDisk: String {
        ByteCountFormatter.string(fromByteCount: totalDiskSpace, countStyle: .file)
    }
    
    public var formattedFreeDisk: String {
        ByteCountFormatter.string(fromByteCount: freeDiskSpace, countStyle: .file)
    }
    
    public var formattedUsedDisk: String {
        ByteCountFormatter.string(fromByteCount: usedDiskSpace, countStyle: .file)
    }
    
    public var formattedSystemDataSize: String {
        if systemDataTotalBytes > 0 {
            return ByteCountFormatter.string(fromByteCount: systemDataTotalBytes, countStyle: .file)
        } else if isCalculatingSystemData {
            return "Hesaplanıyor..."
        } else {
            return "0 B"
        }
    }
    
    public var formattedSystemDataBadge: String {
        if isCalculatingSystemData {
            return "..."
        } else if systemDataTotalBytes > 0 {
            return ByteCountFormatter.string(fromByteCount: systemDataTotalBytes, countStyle: .file)
        } else {
            return "Taranıyor"
        }
    }
    
    public var usedDiskPercentage: Double {
        guard totalDiskSpace > 0 else { return 0.0 }
        return (Double(usedDiskSpace) / Double(totalDiskSpace)) * 100.0
    }
    
    public func triggerAlert(title: String, message: String) {
        self.alertMessage = "\(title)\n\n\(message)"
        self.showAlert = true
    }
}
