import Foundation
import SwiftUI
import AppKit
import Combine

@MainActor
public final class LargeFilesViewModel: ObservableObject {
    @Published public var items: [CleanItem] = []
    @Published public var isLoading: Bool = false
    @Published public var isCleaning: Bool = false
    @Published public var selectedCategory: String = "Tümü"
    @Published public var minSizeFilter: Int64 = 100_000_000 // 100 MB
    @Published public var showResultSheet: Bool = false
    @Published public var lastFreedBytes: Int64 = 0
    
    public let categories = [
        "Tümü",
        "Arşivler ve Yükleyiciler",
        "Yapay Zeka (AI) Ağırlıkları",
        "Videolar",
        "Ses Dosyaları",
        "Veritabanı ve Tasarım Dosyaları",
        "Diğer Büyük Dosyalar"
    ]
    
    public let sizeThresholds: [(label: String, bytes: Int64)] = [
        ("100 MB+", 100_000_000),
        ("500 MB+", 500_000_000),
        ("1 GB+", 1_000_000_000),
        ("5 GB+", 5_000_000_000)
    ]
    
    public init() {}
    
    public var filteredItems: [CleanItem] {
        items.filter { item in
            let categoryMatch = (selectedCategory == "Tümü" || item.category == selectedCategory)
            let sizeMatch = item.size >= minSizeFilter
            return categoryMatch && sizeMatch
        }
    }
    
    public var totalSelectedBytes: Int64 {
        filteredItems.filter({ $0.isSelected }).reduce(0) { $0 + $1.size }
    }
    
    public var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSelectedBytes, countStyle: .file)
    }
    
    public func scan() async {
        isLoading = true
        let found = await LargeFilesService.shared.scanLargeFiles(minSizeBytes: 100_000_000)
        self.items = found
        self.isLoading = false
    }
    
    public func revealInFinder(_ item: CleanItem) {
        let url = URL(fileURLWithPath: item.path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    public func cleanSelected(mode: DeletionMode) async {
        isCleaning = true
        let selected = filteredItems.filter({ $0.isSelected })
        let result = DeletionService.shared.deleteItems(selected, mode: mode)
        
        self.lastFreedBytes = result.freedBytes
        self.items.removeAll(where: { item in selected.contains(where: { $0.id == item.id }) })
        
        self.isCleaning = false
        self.showResultSheet = true
    }
    
    public func toggleSelectAll(select: Bool) {
        let ids = Set(filteredItems.map { $0.id })
        for i in 0..<items.count {
            if ids.contains(items[i].id) {
                items[i].isSelected = select
            }
        }
    }
}
