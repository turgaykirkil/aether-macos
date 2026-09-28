import Foundation
import AppKit

public final class DeletionService {
    public static let shared = DeletionService()
    
    private let fileManager = FileManager.default
    
    // Güvenlik: Asla silinmemesi gereken kritik sistem ve kök dizinler
    private let blacklistedPaths: Set<String> = [
        "/",
        "/System",
        "/System/Library",
        "/Library",
        "/usr",
        "/bin",
        "/sbin",
        "/etc",
        "/var",
        "/private",
        "/Applications",
        "/Users",
        NSHomeDirectory(),
        NSHomeDirectory() + "/Desktop",
        NSHomeDirectory() + "/Documents",
        NSHomeDirectory() + "/Library"
    ]
    
    // İçeriği temizlenip kendisi korunması gereken kök önbellek dizinleri
    private let emptyContentsOnlyPaths: Set<String> = [
        NSHomeDirectory() + "/Library/Caches",
        NSHomeDirectory() + "/Library/Developer/CoreSimulator/Devices",
        NSHomeDirectory() + "/.Trash"
    ]
    
    private init() {}
    
    public func isSafeToDelete(path: String) -> Bool {
        let standardPath = URL(fileURLWithPath: path).standardized.path
        
        if blacklistedPaths.contains(standardPath) {
            return false
        }
        
        if standardPath.hasPrefix("/System") || standardPath.hasPrefix("/usr") || standardPath.hasPrefix("/bin") || standardPath.hasPrefix("/sbin") {
            return false
        }
        
        return true
    }
    
    public func itemExists(atPath path: String) -> Bool {
        var statBuf = stat()
        return lstat(path, &statBuf) == 0
    }
    
    public func isSymbolicLink(atPath path: String) -> Bool {
        var statBuf = stat()
        guard lstat(path, &statBuf) == 0 else { return false }
        return (statBuf.st_mode & S_IFMT) == S_IFLNK
    }
    
    public func deleteItem(at path: String, mode: DeletionMode) throws {
        guard isSafeToDelete(path: path) else {
            throw NSError(
                domain: "MacClean.DeletionService",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "Korumalı sistem dizinleri güvenlik nedeniyle silinemez: \(path)"]
            )
        }
        
        let url = URL(fileURLWithPath: path).standardized
        guard itemExists(atPath: url.path) else { return }
        
        // Eğer sembolik bağlantı (symlink / alias) ise doğrudan bağlantı dosyasını sil
        if isSymbolicLink(atPath: url.path) {
            if unlink(url.path) == 0 {
                return
            }
            if (try? fileManager.removeItem(atPath: url.path)) != nil {
                return
            }
            if removeWithAdminPrivileges(path: url.path) {
                return
            }
            throw NSError(
                domain: "MacClean.DeletionService",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Sembolik bağlantı silinemedi: \(url.path)"]
            )
        }
        
        // Eğer sadece içeriğinin boşaltılması gereken bir klasörse
        if emptyContentsOnlyPaths.contains(url.path) {
            if let children = try? fileManager.contentsOfDirectory(atPath: url.path) {
                for child in children {
                    let childPath = url.path + "/" + child
                    let childURL = URL(fileURLWithPath: childPath)
                    switch mode {
                    case .trash:
                        var res: NSURL?
                        _ = try? fileManager.trashItem(at: childURL, resultingItemURL: &res)
                    case .permanent:
                        _ = try? fileManager.removeItem(at: childURL)
                    }
                }
            }
            return
        }
        
        // Standart Dosya veya Uygulama Paketi Silme
        var deleteSuccess = false
        
        switch mode {
        case .trash:
            // 1. Önce FileManager.trashItem dene
            var resultingURL: NSURL?
            if (try? fileManager.trashItem(at: url, resultingItemURL: &resultingURL)) != nil {
                deleteSuccess = true
            } else {
                // 2. Finder AppleScript ile Çöpe Atmayı dene (Yetki korumalı /Applications için)
                deleteSuccess = trashWithFinder(path: url.path)
            }
            
        case .permanent:
            // 1. Önce FileManager.removeItem dene
            if (try? fileManager.removeItem(at: url)) != nil {
                deleteSuccess = true
            } else {
                // 2. Eğer root/admin yetkisi gerekiyorsa (Örn: /Applications altındaki root sahipli app'ler)
                deleteSuccess = removeWithAdminPrivileges(path: url.path)
            }
        }
        
        // Dosyanın gerçekten silinip silinmediğini teyit et
        if itemExists(atPath: url.path) && !deleteSuccess {
            throw NSError(
                domain: "MacClean.DeletionService",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "\(url.lastPathComponent) silinemedi. macOS dosya izinleri veya yönetici yetkisi gerekebilir."]
            )
        }
    }
    
    private func trashWithFinder(path: String) -> Bool {
        let script = "tell application \"Finder\" to delete POSIX file \"\(path)\""
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            return error == nil
        }
        return false
    }
    
    private func removeWithAdminPrivileges(path: String) -> Bool {
        let script = "do shell script \"rm -rf \\\"\(path)\\\"\" with administrator privileges"
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            return error == nil
        }
        return false
    }
    
    public func deleteItems(_ items: [CleanItem], mode: DeletionMode, onProgress: ((Int, Int) -> Void)? = nil) -> (successCount: Int, failedCount: Int, freedBytes: Int64) {
        var success = 0
        var failed = 0
        var freed: Int64 = 0
        let total = items.count
        
        for (index, item) in items.enumerated() {
            do {
                try deleteItem(at: item.path, mode: mode)
                if !itemExists(atPath: item.path) {
                    success += 1
                    freed += item.size
                } else {
                    failed += 1
                }
            } catch {
                print("Silme hatası (\(item.path)): \(error.localizedDescription)")
                failed += 1
            }
            onProgress?(index + 1, total)
        }
        
        return (success, failed, freed)
    }
    
    public func calculateSize(of url: URL) -> Int64 {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        
        if !isDir.boolValue {
            let attrs = try? fileManager.attributesOfItem(atPath: url.path)
            return (attrs?[.size] as? Int64) ?? 0
        }
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        
        var total: Int64 = 0
        while let fileURL = enumerator.nextObject() as? URL {
            if let resources = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
               resources.isDirectory == false,
               let size = resources.fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}
