import Foundation
import SwiftUI
import Combine

@MainActor
public final class DeveloperCleanViewModel: ObservableObject {
    @Published public var items: [CleanItem] = []
    @Published public var isLoading: Bool = false
    @Published public var isCleaning: Bool = false
    @Published public var selectedFilter: String = "Tümü"
    @Published public var statusMessage: String = ""
    @Published public var showResultSheet: Bool = false
    @Published public var lastFreedBytes: Int64 = 0
    
    public let filterCategories = [
        "Tümü",
        "Yapay Zeka (AI) Modelleri",
        "Paket Yöneticileri",
        "Xcode & iOS Geliştirme",
        "Proje Bağımlılıkları"
    ]
    
    public init() {}
    
    public var filteredItems: [CleanItem] {
        if selectedFilter == "Tümü" {
            return items
        } else {
            return items.filter { $0.category.contains(selectedFilter) }
        }
    }
    
    public var totalSelectedBytes: Int64 {
        items.filter({ $0.isSelected }).reduce(0) { $0 + $1.size }
    }
    
    public var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSelectedBytes, countStyle: .file)
    }
    
    public func scan() async {
        isLoading = true
        statusMessage = "Geliştirici ve AI modelleri taranıyor..."
        let found = await DeveloperCleanerService.shared.scanDeveloperAndAIJunk()
        self.items = found
        self.isLoading = false
        statusMessage = "\(found.count) öğe bulundu (\(formattedSelectedSize))."
    }
    
    public func cleanSelected(mode: DeletionMode) async {
        isCleaning = true
        let selected = items.filter({ $0.isSelected })
        let result = DeletionService.shared.deleteItems(selected, mode: mode)
        
        self.lastFreedBytes = result.freedBytes
        self.items.removeAll(where: { item in selected.contains(where: { $0.id == item.id }) })
        
        self.isCleaning = false
        self.showResultSheet = true
    }
    
    public func toggleAll(select: Bool) {
        for i in 0..<items.count {
            items[i].isSelected = select
        }
    }
}
