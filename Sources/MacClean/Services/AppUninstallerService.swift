import Foundation
import AppKit

public final class AppUninstallerService {
    public static let shared = AppUninstallerService()
    private let fileManager = FileManager.default
    
    private init() {}
    
    public func scanInstalledApplications() async -> [AppBundleItem] {
        var appURLs: [URL] = []
        let appDirs = [
            "/Applications",
            NSHomeDirectory() + "/Applications"
        ]
        
        for dir in appDirs {
            guard fileManager.fileExists(atPath: dir) else { continue }
            if let contents = try? fileManager.contentsOfDirectory(at: URL(fileURLWithPath: dir), includingPropertiesForKeys: nil) {
                for url in contents where url.pathExtension.lowercased() == "app" {
                    appURLs.append(url)
                }
            }
        }
        
        var apps: [AppBundleItem] = []
        for url in appURLs {
            if let appItem = inspectAppBundle(at: url) {
                apps.append(appItem)
            }
        }
        
        return apps.sorted(by: { $0.totalSize > $1.totalSize })
    }
    
    public func inspectAppBundle(at url: URL) -> AppBundleItem? {
        let bundle = Bundle(url: url)
        let info = bundle?.infoDictionary
        
        let appName = (info?["CFBundleDisplayName"] as? String) ??
                      (info?["CFBundleName"] as? String) ??
                      url.deletingPathExtension().lastPathComponent
        
        let bundleId = bundle?.bundleIdentifier ?? ""
        let version = (info?["CFBundleShortVersionString"] as? String) ?? (info?["CFBundleVersion"] as? String) ?? "1.0"
        
        let appSize = DeletionService.shared.calculateSize(of: url)
        let relatedItems = findRelatedItems(forAppName: appName, bundleIdentifier: bundleId)
        
        return AppBundleItem(
            name: appName,
            bundleIdentifier: bundleId,
            appUrl: url,
            appSize: appSize,
            version: version,
            relatedItems: relatedItems
        )
    }
    
    public func findRelatedItems(forAppName appName: String, bundleIdentifier: String) -> [CleanItem] {
        var items: [CleanItem] = []
        let home = NSHomeDirectory()
        
        let baseSearchPaths: [(dir: String, category: String)] = [
            (home + "/Library/Application Support", "Application Support"),
            (home + "/Library/Caches", "Caches (Önbellek)"),
            (home + "/Library/Preferences", "Preferences (Yapılandırma)"),
            (home + "/Library/Saved Application State", "Saved Application State"),
            (home + "/Library/WebKit", "WebKit Verileri"),
            (home + "/Library/Containers", "App Sandboxing (Containers)"),
            (home + "/Library/HTTPStorages", "HTTP Önbellek & Çerezler"),
            (home + "/Library/Logs", "Uygulama Logları")
        ]
        
        let cleanName = appName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanBundle = bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        for (dirPath, category) in baseSearchPaths {
            guard fileManager.fileExists(atPath: dirPath) else { continue }
            guard let contents = try? fileManager.contentsOfDirectory(atPath: dirPath) else { continue }
            
            for item in contents {
                let lowerItem = item.lowercased()
                var matched = false
                
                if !cleanBundle.isEmpty && (lowerItem == cleanBundle || lowerItem == "\(cleanBundle).plist" || lowerItem == "\(cleanBundle).savedstate") {
                    matched = true
                } else if !cleanName.isEmpty && lowerItem == cleanName {
                    matched = true
                }
                
                if matched {
                    let fullPath = dirPath + "/" + item
                    let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: fullPath))
                    var isDir: ObjCBool = false
                    fileManager.fileExists(atPath: fullPath, isDirectory: &isDir)
                    
                    items.append(CleanItem(
                        name: item,
                        path: fullPath,
                        size: size,
                        category: category,
                        detail: fullPath,
                        isDirectory: isDir.boolValue,
                        isSelected: true
                    ))
                }
            }
        }
        
        return items
    }
}
