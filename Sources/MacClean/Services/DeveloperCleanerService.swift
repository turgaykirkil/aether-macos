import Foundation

public final class DeveloperCleanerService {
    public static let shared = DeveloperCleanerService()
    private let fileManager = FileManager.default
    
    private init() {}
    
    public func scanDeveloperAndAIJunk(customScanPaths: [String] = []) async -> [CleanItem] {
        var items: [CleanItem] = []
        let home = NSHomeDirectory()
        
        // 1. AI & Makine Öğrenimi Modelleri (Kullanıcı İncelemesi Önerilir)
        let aiPaths: [(path: String, name: String, category: String, detail: String)] = [
            (home + "/.ollama/models", "Ollama Yerel LLM Modelleri", "Yapay Zeka (AI) Modelleri", "Yerel çalışan Ollama büyük dil modelleri ve ağırlıkları"),
            (home + "/.cache/huggingface", "HuggingFace Model Önbelleği", "Yapay Zeka (AI) Modelleri", "İndirilmiş HuggingFace transformers/diffusers modelleri"),
            (home + "/.cache/torch", "PyTorch Model Önbelleği", "Yapay Zeka (AI) Modelleri", "PyTorch ve TorchVision hazır model ağırlıkları"),
            (home + "/.EasyOCR", "EasyOCR Model Ağırlıkları", "Yapay Zeka (AI) Modelleri", "Karakter tanıma derin öğrenme modelleri"),
            (home + "/.paddleocr", "PaddleOCR Model Ağırlıkları", "Yapay Zeka (AI) Modelleri", "PaddlePaddle OCR model ağırlıkları")
        ]
        
        for ai in aiPaths {
            if fileManager.fileExists(atPath: ai.path) {
                let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: ai.path))
                if size > 10_000_000 { // 10 MB+
                    items.append(CleanItem(
                        name: ai.name,
                        path: ai.path,
                        size: size,
                        category: ai.category,
                        detail: ai.detail,
                        isDirectory: true,
                        isSelected: false, // AI modelleri varsayılan olarak seçilmez (güvenlik için)
                        safetyLevel: .userReview
                    ))
                }
            }
        }
        
        // 2. Paket Yöneticisi Önbellekleri (Güvenli Çöp - Kolayca Rejenere Edilir)
        let pkgPaths: [(path: String, name: String, category: String, detail: String)] = [
            (home + "/.npm", "NPM Global Önbellek", "Paket Yöneticileri", "Node.js npm indirme ve paket önbelleği"),
            (home + "/.yarn", "Yarn Global Önbellek", "Paket Yöneticileri", "Yarn paket arşivi ve önbelleği"),
            (home + "/.pnpm-store", "pnpm Global Store", "Paket Yöneticileri", "pnpm merkezi paket deposu"),
            (home + "/.gradle/caches", "Gradle Build Önbelleği", "Paket Yöneticileri", "Android / Java Gradle paket ve bağımlılık önbelleği"),
            (home + "/.cargo/registry/cache", "Rust Cargo Önbelleği", "Paket Yöneticileri", "Rust crates.io indirilmiş paket önbelleği"),
            (home + "/.cocoapods/repos", "CocoaPods Specs & Repolar", "Paket Yöneticileri", "iOS CocoaPods master repository ve specs önbelleği"),
            (home + "/Library/Caches/Homebrew", "Homebrew İndirme Önbelleği", "Paket Yöneticileri", "Brew tarafından indirilmiş eski paket ve bottle arşivleri"),
            (home + "/.cache/pip", "Python Pip Önbelleği", "Paket Yöneticileri", "Python pip wheel ve paket indirme önbelleği")
        ]
        
        for pkg in pkgPaths {
            if fileManager.fileExists(atPath: pkg.path) {
                let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: pkg.path))
                if size > 10_000_000 { // 10 MB+
                    items.append(CleanItem(
                        name: pkg.name,
                        path: pkg.path,
                        size: size,
                        category: pkg.category,
                        detail: pkg.detail,
                        isDirectory: true,
                        isSelected: true,
                        safetyLevel: .safeJunk
                    ))
                }
            }
        }
        
        // 3. Xcode ve Apple Geliştirici Artıkları (Güvenli Çöp)
        let xcodePaths: [(path: String, name: String, category: String, detail: String)] = [
            (home + "/Library/Developer/Xcode/DerivedData", "Xcode DerivedData", "Xcode & iOS Geliştirme", "Derleme ara ürünleri, indeksler ve modül önbellekleri"),
            (home + "/Library/Developer/Xcode/Archives", "Xcode Arşivleri (Archives)", "Xcode & iOS Geliştirme", "Eski TestFlight ve App Store derleme arşivleri"),
            (home + "/Library/Developer/Xcode/iOS DeviceSupport", "Eski iOS Device Support", "Xcode & iOS Geliştirme", "Fiziksel cihaz sembolik hata ayıklama dosyaları"),
            (home + "/Library/Developer/CoreSimulator/Caches", "iOS Simülatör Önbellekleri", "Xcode & iOS Geliştirme", "Simülatör çalışma ortamı ve uygulama önbellekleri")
        ]
        
        for xc in xcodePaths {
            if fileManager.fileExists(atPath: xc.path) {
                let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: xc.path))
                if size > 10_000_000 { // 10 MB+
                    items.append(CleanItem(
                        name: xc.name,
                        path: xc.path,
                        size: size,
                        category: xc.category,
                        detail: xc.detail,
                        isDirectory: true,
                        isSelected: true,
                        safetyLevel: .safeJunk
                    ))
                }
            }
        }
        
        // 4. Proje Klasörlerindeki Ağır Dizinler (node_modules, .next, build, target)
        var projectRoots = [
            home + "/Apps",
            home + "/Projeler",
            home + "/Projects",
            home + "/Developer",
            home + "/Desktop"
        ]
        projectRoots.append(contentsOf: customScanPaths)
        
        let runningPaths = ProjectActivityService.shared.getRunningProcessWorkingPaths()
        
        for root in projectRoots {
            guard fileManager.fileExists(atPath: root) else { continue }
            let foundBloat = await scanDirectoryForProjectBloat(rootPath: root, runningPaths: runningPaths)
            items.append(contentsOf: foundBloat)
        }
        
        return items.sorted(by: { $0.size > $1.size })
    }
    
    private func scanDirectoryForProjectBloat(rootPath: String, runningPaths: Set<String>) async -> [CleanItem] {
        var results: [CleanItem] = []
        let targetFolderNames: Set<String> = ["node_modules", ".next", "dist", "build", "target", ".dart_tool"]
        
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: rootPath),
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return results }
        
        while let fileURL = enumerator.nextObject() as? URL {
            let lastComponent = fileURL.lastPathComponent
            if targetFolderNames.contains(lastComponent) {
                enumerator.skipDescendants()
                
                let projectDirectory = fileURL.deletingLastPathComponent()
                let parentProjectName = projectDirectory.lastPathComponent
                
                // Akıllı Güvenlik Değerlendirmesi
                let eval = ProjectActivityService.shared.evaluateProjectSafety(projectDirectory: projectDirectory, runningPaths: runningPaths)
                
                let size = DeletionService.shared.calculateSize(of: fileURL)
                if size > 20_000_000 { // 20 MB+
                    results.append(CleanItem(
                        name: "\(parentProjectName) / \(lastComponent)",
                        path: fileURL.path,
                        size: size,
                        category: "Proje Bağımlılıkları (\(lastComponent))",
                        detail: "\(eval.reason) Yol: \(projectDirectory.path)",
                        isDirectory: true,
                        isSelected: eval.safety.shouldAutoSelect,
                        lastModified: eval.lastModified,
                        safetyLevel: eval.safety
                    ))
                }
            }
        }
        return results
    }
}
