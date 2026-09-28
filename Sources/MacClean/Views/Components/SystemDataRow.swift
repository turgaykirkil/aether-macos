import SwiftUI

public struct SystemDataRow: View {
    let item: SystemDataBreakdownItem
    let onTrash: () -> Void
    let onPermanentDelete: () -> Void
    
    public init(item: SystemDataBreakdownItem, onTrash: @escaping () -> Void, onPermanentDelete: @escaping () -> Void) {
        self.item = item
        self.onTrash = onTrash
        self.onPermanentDelete = onPermanentDelete
    }
    
    public var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: getIcon(for: item.category))
                    .font(.system(size: 22))
                    .foregroundColor(getColor(for: item.category))
                    .frame(width: 34)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .bold))
                        
                        Text(item.category)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(getColor(for: item.category).opacity(0.12))
                            .foregroundColor(getColor(for: item.category))
                            .cornerRadius(4)
                    }
                    
                    Text(item.detail)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text(item.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text(item.formattedSize)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        Button(action: onTrash) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text(LanguageManager.shared.localized("Move to Trash", "Çöpe Taşı"))
                            }
                            .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .help(LanguageManager.shared.localized("Move items to macOS Trash", "Dosyaları macOS Çöp Sepeti'ne gönder"))
                        
                        Button(action: onPermanentDelete) {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                Text(LanguageManager.shared.localized("Delete Forever", "Tamamen Sil"))
                            }
                            .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .help(LanguageManager.shared.localized("Delete items permanently from disk", "Dosyaları diskten kalıcı olarak sil"))
                    }
                }
            }
        }
    }
    
    func getIcon(for category: String) -> String {
        if category.contains("Xcode") || category.contains("Simülatör") {
            return "hammer.fill"
        } else if category.contains("Homebrew") {
            return "shippingbox.fill"
        } else if category.contains("Snapshots") {
            return "clock.arrow.circlepath"
        } else if category.contains("AI") {
            return "cpu.fill"
        } else {
            return "folder.fill"
        }
    }
    
    func getColor(for category: String) -> Color {
        if category.contains("Xcode") || category.contains("Simülatör") {
            return .blue
        } else if category.contains("Homebrew") {
            return .orange
        } else if category.contains("Snapshots") {
            return .green
        } else if category.contains("AI") {
            return .purple
        } else {
            return .pink
        }
    }
}
