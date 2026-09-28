import Foundation
import SwiftUI
import Combine

@MainActor
public final class SystemDataViewModel: ObservableObject {
    @Published public var items: [SystemDataBreakdownItem] = []
    @Published public var isLoading: Bool = false
    @Published public var isRunningCommand: Bool = false
    @Published public var statusMessage: String = ""
    @Published public var showAlert: Bool = false
    @Published public var alertMessage: String = ""
    
    public init() {}
    
    public var totalScannedBytes: Int64 {
        items.reduce(0) { $0 + $1.size }
    }
    
    public var formattedTotalScanned: String {
        ByteCountFormatter.string(fromByteCount: totalScannedBytes, countStyle: .file)
    }
    
    public func analyze() async {
        isLoading = true
        statusMessage = "macOS Sistem Verileri (System Data) taranıyor..."
        let found = await SystemDataService.shared.analyzeSystemData()
        self.items = found
        self.isLoading = false
        statusMessage = "Sistem Verileri dökümü tamamlandı (\(formattedTotalScanned) tespit edildi)."
    }
    
    public func executeCommand(for item: SystemDataBreakdownItem) async {
        guard let cmd = item.cleanCommand else { return }
        isRunningCommand = true
        statusMessage = "\(cmd) çalıştırılıyor..."
        
        let success = await SystemDataService.shared.executeCleanCommand(command: cmd)
        isRunningCommand = false
        
        if success {
            self.alertMessage = "\(item.title) için '\(cmd)' komutu başarıyla çalıştırıldı ve sistem alanı temizlendi."
        } else {
            self.alertMessage = "'\(cmd)' komutu çalıştırılırken bir hata oluştu veya yetki gerekebilir."
        }
        self.showAlert = true
        
        // Yeniden analiz et
        await analyze()
    }
    
    public func deleteItem(item: SystemDataBreakdownItem, mode: DeletionMode) async {
        guard DeletionService.shared.isSafeToDelete(path: item.path) else {
            self.alertMessage = "Korumalı sistem dizinleri güvenlik nedeniyle doğrudan silinemez: \(item.path)"
            self.showAlert = true
            return
        }
        
        do {
            try DeletionService.shared.deleteItem(at: item.path, mode: mode)
            self.alertMessage = "\(item.title) başarıyla temizlendi."
            self.items.removeAll(where: { $0.id == item.id })
        } catch {
            self.alertMessage = "Silme hatası: \(error.localizedDescription)"
        }
        self.showAlert = true
    }
}
