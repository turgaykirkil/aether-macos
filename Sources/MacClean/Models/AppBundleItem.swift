import Foundation
import AppKit

public struct AppBundleItem: Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let bundleIdentifier: String
    public let appUrl: URL
    public let appSize: Int64
    public let version: String
    public var relatedItems: [CleanItem]
    public var isSelected: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String,
        appUrl: URL,
        appSize: Int64,
        version: String,
        relatedItems: [CleanItem] = [],
        isSelected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.appUrl = appUrl
        self.appSize = appSize
        self.version = version
        self.relatedItems = relatedItems
        self.isSelected = isSelected
    }
    
    public var totalSize: Int64 {
        let relatedTotal = relatedItems.reduce(0) { $0 + $1.size }
        return appSize + relatedTotal
    }
    
    public var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    public var formattedAppSize: String {
        ByteCountFormatter.string(fromByteCount: appSize, countStyle: .file)
    }
    
    public var appIcon: NSImage {
        NSWorkspace.shared.icon(forFile: appUrl.path)
    }
}
