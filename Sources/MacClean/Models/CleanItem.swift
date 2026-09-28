import Foundation
import SwiftUI

public struct CleanItem: Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let path: String
    public let size: Int64
    public let category: String
    public let detail: String
    public let isDirectory: Bool
    public var isSelected: Bool
    public let lastModified: Date?
    public let safetyLevel: SafetyLevel
    
    public init(
        id: UUID = UUID(),
        name: String,
        path: String,
        size: Int64,
        category: String,
        detail: String = "",
        isDirectory: Bool = false,
        isSelected: Bool? = nil,
        lastModified: Date? = nil,
        safetyLevel: SafetyLevel = .safeJunk
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.size = size
        self.category = category
        self.detail = detail
        self.isDirectory = isDirectory
        self.safetyLevel = safetyLevel
        self.lastModified = lastModified
        self.isSelected = isSelected ?? safetyLevel.shouldAutoSelect
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    public var formattedDate: String {
        guard let date = lastModified else { return "Bilinmiyor" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
    
    public var daysSinceModified: Int? {
        guard let date = lastModified else { return nil }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day
    }
}
