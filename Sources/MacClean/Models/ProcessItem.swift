import Foundation

public struct ProcessItem: Identifiable, Hashable {
    public let id: Int32 // PID
    public let name: String
    public let command: String
    public let cpuPercent: Double
    public let memBytes: Int64
    public var isSelected: Bool
    public let isSystemProcess: Bool
    
    public init(
        pid: Int32,
        name: String,
        command: String,
        cpuPercent: Double,
        memBytes: Int64,
        isSelected: Bool = false,
        isSystemProcess: Bool = false
    ) {
        self.id = pid
        self.name = name
        self.command = command
        self.cpuPercent = cpuPercent
        self.memBytes = memBytes
        self.isSelected = isSelected
        self.isSystemProcess = isSystemProcess
    }
    
    public var formattedMemory: String {
        ByteCountFormatter.string(fromByteCount: memBytes, countStyle: .memory)
    }
}
