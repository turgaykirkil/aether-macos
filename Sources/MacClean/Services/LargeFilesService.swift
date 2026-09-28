import Foundation

public final class LargeFilesService {
    public static let shared = LargeFilesService()
    private let fileManager = FileManager.default
    
    private init() {}
    
    public func scanLargeFiles(minSizeBytes: Int64 = 50_000_000) async -> [CleanItem] {
        var items: [CleanItem] = []
        var seenPaths: Set<String> = []
        let home = NSHomeDirectory()
        
        // 1. macOS Spotlight (mdfind) ile 0.1 saniyede sistemdeki tüm büyük dosyaları yakala
        let mdfindItems = scanViaSpotlight(minSizeBytes: minSizeBytes, homeDir: home)
        for item in mdfindItems {
            if !seenPaths.contains(item.path) {
                seenPaths.insert(item.path)
                items.append(item)
            }
        }
        
        // 2. Spotlight indeksinde olmayan veya taranmamış ek kullanıcı dizinlerini tara
        let searchRoots = [
            home + "/Downloads",
            home + "/Desktop",
            home + "/Documents",
            home + "/Movies",
            home + "/Music",
            home + "/Pictures",
            home + "/Apps"
        ]
        
        for root in searchRoots {
            guard fileManager.fileExists(atPath: root) else { continue }
            guard let enumerator = fileManager.enumerator(
                at: URL(fileURLWithPath: root),
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            
            while let fileURL = enumerator.nextObject() as? URL {
                if seenPaths.contains(fileURL.path) { continue }
                
                if let resources = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey]),
                   resources.isDirectory == false,
                   let size = resources.fileSize,
                   Int64(size) >= minSizeBytes {
                    
                    seenPaths.insert(fileURL.path)
                    let ext = fileURL.pathExtension.lowercased()
                    let category = categorizeExtension(ext)
                    
                    items.append(CleanItem(
                        name: fileURL.lastPathComponent,
                        path: fileURL.path,
                        size: Int64(size),
                        category: category,
                        detail: fileURL.deletingLastPathComponent().path,
                        isDirectory: false,
                        isSelected: false,
                        lastModified: resources.contentModificationDate
                    ))
                }
            }
        }
        
        return items.sorted(by: { $0.size > $1.size })
    }
    
    private func scanViaSpotlight(minSizeBytes: Int64, homeDir: String) -> [CleanItem] {
        var results: [CleanItem] = []
        let task = Process()
        task.launchPath = "/usr/bin/mdfind"
        task.arguments = ["-onlyin", homeDir, "kMDItemFSSize >= \(minSizeBytes)"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            let lines = output.components(separatedBy: .newlines)
            for path in lines where !path.trimmingCharacters(in: .whitespaces).isEmpty {
                // ~/Library/Application Support gibi dahili cache'leri temiz tutmak için filtrele
                if path.contains("/Library/Caches") || path.contains("/Library/Containers") {
                    continue
                }
                
                let url = URL(fileURLWithPath: path)
                var isDir: ObjCBool = false
                guard fileManager.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue else { continue }
                
                let attrs = try? fileManager.attributesOfItem(atPath: path)
                let size = (attrs?[.size] as? Int64) ?? 0
                guard size >= minSizeBytes else { continue }
                
                let modDate = attrs?[.modificationDate] as? Date
                let ext = url.pathExtension.lowercased()
                let category = categorizeExtension(ext)
                
                results.append(CleanItem(
                    name: url.lastPathComponent,
                    path: path,
                    size: size,
                    category: category,
                    detail: url.deletingLastPathComponent().path,
                    isDirectory: false,
                    isSelected: false,
                    lastModified: modDate
                ))
            }
        } catch {
            return []
        }
        return results
    }
    
    private func categorizeExtension(_ ext: String) -> String {
        switch ext {
        case "dmg", "pkg", "iso", "zip", "tar", "gz", "7z", "rar", "tgz", "xz":
            return "Arşivler ve Yükleyiciler"
        case "safetensors", "gguf", "bin", "onnx", "pth", "pt", "ckpt", "model", "h5":
            return "Yapay Zeka (AI) Ağırlıkları"
        case "mov", "mp4", "mkv", "avi", "m4v", "wmv", "flv", "webm":
            return "Videolar"
        case "mp3", "wav", "flac", "aac", "m4a", "aiff", "alac":
            return "Ses Dosyaları"
        case "sqlite", "db", "sql", "psd", "sketch", "fig", "ai", "xd":
            return "Veritabanı ve Tasarım Dosyaları"
        case "app", "dylib", "node", "apk", "ipa", "so":
            return "Derleme ve İkili Dosyalar"
        default:
            return "Diğer Büyük Dosyalar"
        }
    }
}
