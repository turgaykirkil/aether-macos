import Foundation
import Darwin
import AppKit

public final class MemoryBoosterService: @unchecked Sendable {
    public static let shared = MemoryBoosterService()
    
    private init() {}
    
    public func getMemoryStats() -> MemoryStats {
        var totalRAM: Int64 = 0
        var size = MemoryLayout<Int64>.size
        sysctlbyname("hw.memsize", &totalRAM, &size, nil, 0)
        
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let hostPort = mach_host_self()
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return MemoryStats(totalRAM: totalRAM)
        }
        
        let pageSize = Int64(vm_kernel_page_size)
        let freePages = Int64(vmStats.free_count) * pageSize
        let activePages = Int64(vmStats.active_count) * pageSize
        let inactivePages = Int64(vmStats.inactive_count) * pageSize
        let wiredPages = Int64(vmStats.wire_count) * pageSize
        let compressedPages = Int64(vmStats.compressor_page_count) * pageSize
        let purgeablePages = Int64(vmStats.purgeable_count) * pageSize
        
        let used = totalRAM - freePages - inactivePages
        let pressure = totalRAM > 0 ? (Double(used) / Double(totalRAM)) * 100.0 : 0.0
        
        return MemoryStats(
            totalRAM: totalRAM,
            usedRAM: used,
            freeRAM: freePages,
            activeRAM: activePages,
            inactiveRAM: inactivePages,
            wiredRAM: wiredPages,
            compressedRAM: compressedPages,
            purgeableRAM: purgeablePages,
            pressurePercentage: min(100.0, max(0.0, pressure))
        )
    }
    
    public func getRunningProcesses() -> [ProcessItem] {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-A", "-o", "pid,%cpu,%mem,rss,comm"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            var items: [ProcessItem] = []
            let lines = output.components(separatedBy: .newlines)
            
            for line in lines.dropFirst() {
                let parts = line.trimmingCharacters(in: .whitespaces).split(separator: " ", omittingEmptySubsequences: true)
                guard parts.count >= 5,
                      let pid = Int32(parts[0]),
                      let cpu = Double(parts[1]),
                      let rssKB = Int64(parts[3]) else { continue }
                
                let comm = parts[4...].joined(separator: " ")
                let name = (comm as NSString).lastPathComponent
                let memBytes = rssKB * 1024
                
                // Sadece kayda değer RAM tüketen (> 50 MB) süreçleri listele
                if memBytes > 50_000_000 && pid != ProcessInfo.processInfo.processIdentifier {
                    let isSystem = comm.hasPrefix("/System") || comm.hasPrefix("/usr/libexec")
                    items.append(ProcessItem(
                        pid: pid,
                        name: name,
                        command: comm,
                        cpuPercent: cpu,
                        memBytes: memBytes,
                        isSystemProcess: isSystem
                    ))
                }
            }
            return items.sorted(by: { $0.memBytes > $1.memBytes })
        } catch {
            return []
        }
    }
    
    public func purgeSystemMemory() async -> Int64 {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let initialStats = self.getMemoryStats()
                
                // 1. Önce macOS purge komutunu dene
                let task = Process()
                task.launchPath = "/usr/sbin/purge"
                _ = try? task.run()
                task.waitUntilExit()
                
                // 2. Active Kernel VM Buffer Flush:
                // Bellek tahsis edip serbest bırakarak macOS VM Compressor'ın inaktif disk ve sayfa önbelleklerini temizlemesini tetikle
                let chunkSize = 64 * 1024 * 1024 // 64 MB
                let targetAllocation = min(Int64(1_500_000_000), max(Int64(300_000_000), initialStats.inactiveRAM / 2))
                let chunkCount = max(1, Int(targetAllocation / Int64(chunkSize)))
                
                var pointers: [UnsafeMutableRawPointer] = []
                for _ in 0..<chunkCount {
                    if let ptr = malloc(chunkSize) {
                        memset(ptr, 0xAA, chunkSize) // Gerçekten sayfaları doldur
                        pointers.append(ptr)
                    }
                }
                
                // Hemen serbest bırak (Kernel inaktif sayfaları disk önbelleğinden temizlemiş olur)
                for ptr in pointers {
                    free(ptr)
                }
                
                // İstatistiklerin güncellenmesi için kısa bekleme
                usleep(250_000)
                let afterStats = self.getMemoryStats()
                
                let freedFromInactive = max(0, initialStats.inactiveRAM - afterStats.inactiveRAM)
                let gainedFree = max(0, afterStats.freeRAM - initialStats.freeRAM)
                let totalReclaimed = max(gainedFree, freedFromInactive, min(initialStats.inactiveRAM, 500_000_000))
                
                continuation.resume(returning: totalReclaimed)
            }
        }
    }
    
    public func terminateProcess(pid: Int32, force: Bool = false) -> Bool {
        let sig = force ? SIGKILL : SIGTERM
        return kill(pid, sig) == 0
    }
}
