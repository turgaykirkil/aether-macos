import SwiftUI

public struct StorageBreakdownBar: View {
    let totalBytes: Int64
    let usedBytes: Int64
    let freeBytes: Int64
    
    public init(totalBytes: Int64, usedBytes: Int64, freeBytes: Int64) {
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.freeBytes = freeBytes
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Multi-segment Bar
            GeometryReader { geo in
                HStack(spacing: 3) {
                    // System Data (~50% of used)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [Color.pink.opacity(0.8), Color.pink], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * CGFloat(Double(usedBytes * 55 / 100) / Double(max(1, totalBytes)))))
                    
                    // Apps & User Data (~35% of used)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [Color.blue.opacity(0.8), Color.blue], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * CGFloat(Double(usedBytes * 35 / 100) / Double(max(1, totalBytes)))))
                    
                    // AI & Dev Caches (~10% of used)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [Color.purple.opacity(0.8), Color.purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * CGFloat(Double(usedBytes * 10 / 100) / Double(max(1, totalBytes)))))
                    
                    // Free Space
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: max(8, geo.size.width * CGFloat(Double(freeBytes) / Double(max(1, totalBytes)))))
                }
            }
            .frame(height: 14)
            .background(Color.black.opacity(0.2))
            .cornerRadius(6)
            
            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .pink, title: "Sistem Verileri (110+ GB)")
                LegendItem(color: .blue, title: "Uygulamalar & Belgeler")
                LegendItem(color: .purple, title: "AI & Geliştirici")
                LegendItem(color: .gray.opacity(0.6), title: "Kullanılabilir Boş Alan")
            }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}
