import Foundation

public final class SystemCleanerService {
    public static let shared = SystemCleanerService()
    private let fileManager = FileManager.default
    
    private init() {}
    
    public func scanSystemJunk() async -> [CleanItem] {
        var items: [CleanItem] = []
        let home = NSHomeDirectory()
        
        // 1. User Caches (~/Library/Caches)
        let cachesPath = home + "/Library/Caches"
        if let cacheItems = try? fileManager.contentsOfDirectory(atPath: cachesPath) {
            for name in cacheItems {
                if name.hasPrefix(".") { continue }
                let fullPath = cachesPath + "/" + name
                let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: fullPath))
                if size > 1_000_000 { // 1 MB'den büyük olanları listele
                    items.append(CleanItem(
                        name: "Önbellek: \(name)",
                        path: fullPath,
                        size: size,
                        category: "Kullanıcı Önbellekleri",
                        detail: "Uygulama ve tarayıcı geçici veri önbelleği",
                        isDirectory: true
                    ))
                }
            }
        }
        
        // 2. User Logs (~/Library/Logs)
        let logsPath = home + "/Library/Logs"
        if let logItems = try? fileManager.contentsOfDirectory(atPath: logsPath) {
            for name in logItems {
                let fullPath = logsPath + "/" + name
                let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: fullPath))
                if size > 100_000 { // 100 KB+
                    items.append(CleanItem(
                        name: "Log: \(name)",
                        path: fullPath,
                        size: size,
                        category: "Sistem ve Uygulama Günlükleri (Logs)",
                        detail: "Uygulama çalışma ve hata günlükleri",
                        isDirectory: true
                    ))
                }
            }
        }
        
        // 3. Crash & Diagnostic Reports
        let diagPath = home + "/Library/Logs/DiagnosticReports"
        if fileManager.fileExists(atPath: diagPath) {
            let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: diagPath))
            if size > 0 {
                items.append(CleanItem(
                    name: "Çökme Raporları (Crash Reports)",
                    path: diagPath,
                    size: size,
                    category: "Tanılama Raporları",
                    detail: "Uygulama çökme ve analiz kayıtları",
                    isDirectory: true
                ))
            }
        }
        
        // 4. macOS Trash (~/.Trash)
        let trashPath = home + "/.Trash"
        if let trashFiles = try? fileManager.contentsOfDirectory(atPath: trashPath) {
            for name in trashFiles {
                let fullPath = trashPath + "/" + name
                let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: fullPath))
                items.append(CleanItem(
                    name: "Çöp Kutusu: \(name)",
                    path: fullPath,
                    size: size,
                    category: "Çöp Sepeti",
                    detail: "Kullanıcı tarafından çöpe atılmış dosya",
                    isDirectory: (try? fileManager.attributesOfItem(atPath: fullPath)[.type] as? FileAttributeType) == .typeDirectory
                ))
            }
        }
        
        // 5. Downloads klasöründeki eski yükleyiciler (.dmg, .pkg)
        let downloadsPath = home + "/Downloads"
        if let downloadFiles = try? fileManager.contentsOfDirectory(atPath: downloadsPath) {
            for name in downloadFiles {
                let ext = (name as NSString).pathExtension.lowercased()
                if ["dmg", "pkg", "iso"].contains(ext) {
                    let fullPath = downloadsPath + "/" + name
                    let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: fullPath))
                    items.append(CleanItem(
                        name: "Yükleyici: \(name)",
                        path: fullPath,
                        size: size,
                        category: "Eski Kurulum Dosyaları",
                        detail: "İndirilenler klasöründeki .\(ext) kalıntısı",
                        isDirectory: false
                    ))
                }
            }
        }
        
        return items.sorted(by: { $0.size > $1.size })
    }
}
