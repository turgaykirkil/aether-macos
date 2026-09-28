import Foundation
import SwiftUI

public struct MemoryStats {
    public var totalRAM: Int64
    public var usedRAM: Int64
    public var freeRAM: Int64
    public var activeRAM: Int64
    public var inactiveRAM: Int64
    public var wiredRAM: Int64
    public var compressedRAM: Int64
    public var purgeableRAM: Int64
    public var pressurePercentage: Double // 0 - 100
    
    public init(
        totalRAM: Int64 = 0,
        usedRAM: Int64 = 0,
        freeRAM: Int64 = 0,
        activeRAM: Int64 = 0,
        inactiveRAM: Int64 = 0,
        wiredRAM: Int64 = 0,
        compressedRAM: Int64 = 0,
        purgeableRAM: Int64 = 0,
        pressurePercentage: Double = 0.0
    ) {
        self.totalRAM = totalRAM
        self.usedRAM = usedRAM
        self.freeRAM = freeRAM
        self.activeRAM = activeRAM
        self.inactiveRAM = inactiveRAM
        self.wiredRAM = wiredRAM
        self.compressedRAM = compressedRAM
        self.purgeableRAM = purgeableRAM
        self.pressurePercentage = pressurePercentage
    }
    
    public var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalRAM, countStyle: .memory)
    }
    
    public var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: usedRAM, countStyle: .memory)
    }
    
    public var formattedFree: String {
        ByteCountFormatter.string(fromByteCount: freeRAM, countStyle: .memory)
    }
    
    public var formattedInactive: String {
        ByteCountFormatter.string(fromByteCount: inactiveRAM, countStyle: .memory)
    }
    
    public var formattedPurgeable: String {
        ByteCountFormatter.string(fromByteCount: purgeableRAM, countStyle: .memory)
    }
    
    public var formattedCompressed: String {
        ByteCountFormatter.string(fromByteCount: compressedRAM, countStyle: .memory)
    }
    
    public var formattedWired: String {
        ByteCountFormatter.string(fromByteCount: wiredRAM, countStyle: .memory)
    }
    
    public var pressureColor: Color {
        if pressurePercentage < 50 {
            return .green
        } else if pressurePercentage < 80 {
            return .orange
        } else {
            return .red
        }
    }
    
    public var pressureText: String {
        if pressurePercentage < 50 {
            return "Normal"
        } else if pressurePercentage < 80 {
            return "Orta (Uyarı)"
        } else {
            return "Kritik (Yüksek)"
        }
    }
}
