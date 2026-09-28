import Foundation

public struct SystemDataBreakdownItem: Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let path: String
    public let size: Int64
    public let category: String
    public let detail: String
    public let isPurgeable: Bool
    public var isSelected: Bool
    public let cleanCommand: String?
    
    public init(
        id: UUID = UUID(),
        title: String,
        path: String,
        size: Int64,
        category: String,
        detail: String,
        isPurgeable: Bool = true,
        isSelected: Bool = false,
        cleanCommand: String? = nil
    ) {
        self.id = id
        self.title = title
        self.path = path
        self.size = size
        self.category = category
        self.detail = detail
        self.isPurgeable = isPurgeable
        self.isSelected = isSelected
        self.cleanCommand = cleanCommand
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

public final class SystemDataService {
    public static let shared = SystemDataService()
    private let fileManager = FileManager.default
    
    private init() {}
    
    public func analyzeSystemData() async -> [SystemDataBreakdownItem] {
        var items: [SystemDataBreakdownItem] = []
        let home = NSHomeDirectory()
        
        // 1. Xcode & iOS Geliştirici Dosyaları (~16-30 GB)
        let simDevicesPath = home + "/Library/Developer/CoreSimulator/Devices"
        if fileManager.fileExists(atPath: simDevicesPath) {
            let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: simDevicesPath))
            if size > 100_000_000 {
                items.append(SystemDataBreakdownItem(
                    title: "iOS Simülatör Cihaz Alanları",
                    path: simDevicesPath,
                    size: size,
                    category: "Geliştirici (Xcode / Simülatör)",
                    detail: "Kullanılmayan sanal iOS/iPadOS cihaz diskleri ve uygulama verileri",
                    isPurgeable: true,
                    isSelected: false,
                    cleanCommand: "xcrun simctl delete unavailable"
                ))
            }
        }
        
        let derivedDataPath = home + "/Library/Developer/Xcode/DerivedData"
        if fileManager.fileExists(atPath: derivedDataPath) {
            let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: derivedDataPath))
            if size > 50_000_000 {
                items.append(SystemDataBreakdownItem(
                    title: "Xcode DerivedData & Modül İndeksleri",
                    path: derivedDataPath,
                    size: size,
                    category: "Geliştirici (Xcode)",
                    detail: "Xcode derleme ara ürünleri, derleme önbellekleri ve indeksler",
                    isPurgeable: true,
                    isSelected: true
                ))
            }
        }
        
        let deviceSupportPath = home + "/Library/Developer/Xcode/iOS DeviceSupport"
        if fileManager.fileExists(atPath: deviceSupportPath) {
            let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: deviceSupportPath))
            if size > 100_000_000 {
                items.append(SystemDataBreakdownItem(
                    title: "Eski iOS Device Support Sembolleri",
                    path: deviceSupportPath,
                    size: size,
                    category: "Geliştirici (Xcode)",
                    detail: "Fiziksel cihaz sembolik hata ayıklama dosyaları",
                    isPurgeable: true,
                    isSelected: true
                ))
            }
        }
        
        // 2. Homebrew Paket Deposu (/opt/homebrew) (~9 GB)
        let brewCellar = "/opt/homebrew/Cellar"
        let brewCaskroom = "/opt/homebrew/Caskroom"
        if fileManager.fileExists(atPath: brewCellar) {
            let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: brewCellar))
            items.append(SystemDataBreakdownItem(
                title: "Homebrew Yüklü Paketler (Cellar)",
                path: brewCellar,
                size: size,
                category: "Paket Yöneticileri (Homebrew)",
                detail: "Terminal üzerinden kurulan CLI araçları ve kütüphaneler",
                isPurgeable: false,
                isSelected: false,
                cleanCommand: "brew cleanup -s"
            ))
        }
        if fileManager.fileExists(atPath: brewCaskroom) {
            let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: brewCaskroom))
            if size > 100_000_000 {
                items.append(SystemDataBreakdownItem(
                    title: "Homebrew Cask Kurulum Arşivleri",
                    path: brewCaskroom,
                    size: size,
                    category: "Paket Yöneticileri (Homebrew)",
                    detail: "Homebrew Cask tarafından indirilmiş uygulama kurulum dosyaları",
                    isPurgeable: true,
                    isSelected: false,
                    cleanCommand: "brew cleanup -s --prune=all"
                ))
            }
        }
        
        // 3. Application Support İçindeki Ağır Uygulama Verileri
        let appSupportPath = home + "/Library/Application Support"
        if let apps = try? fileManager.contentsOfDirectory(atPath: appSupportPath) {
            for app in apps {
                if app.hasPrefix(".") { continue }
                let fullPath = appSupportPath + "/" + app
                let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: fullPath))
                if size > 500_000_000 { // 500 MB+ olan büyük klasörleri tek tek dök
                    items.append(SystemDataBreakdownItem(
                        title: "App Support: \(app)",
                        path: fullPath,
                        size: size,
                        category: "Uygulama Verileri (Application Support)",
                        detail: "Uygulama veritabanı, önbellekleri ve dahili verileri",
                        isPurgeable: true,
                        isSelected: false
                    ))
                }
            }
        }
        
        // 4. Kullanıcı Kütüphane Önbellekleri (~/Library/Caches)
        let cachesPath = home + "/Library/Caches"
        if fileManager.fileExists(atPath: cachesPath) {
            let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: cachesPath))
            items.append(SystemDataBreakdownItem(
                title: "macOS Kullanıcı Uygulama Önbellekleri",
                path: cachesPath,
                size: size,
                category: "Sistem ve Uygulama Önbellekleri",
                detail: "Tüm uygulamaların disk önbellek havuzu (Caches)",
                isPurgeable: true,
                isSelected: false
            ))
        }
        
        // 5. APFS Time Machine Yerel Yedekleri (Local Snapshots)
        let snapshots = checkLocalSnapshots()
        if !snapshots.isEmpty {
            items.append(SystemDataBreakdownItem(
                title: "APFS Yerel Time Machine Anlık Görüntüleri",
                path: "/ (APFS Snapshots)",
                size: Int64(snapshots.count) * 2_000_000_000, // Ortalama snapshot tahmini
                category: "macOS Sistem Yedekleri (Snapshots)",
                detail: "\(snapshots.count) adet yerel Time Machine anlık görüntüsü tespit edildi.",
                isPurgeable: true,
                isSelected: false,
                cleanCommand: "tmutil thinlocalsnapshots / 999999999999 4"
            ))
        }
        
        // 6. Kullanıcı Gizli AI & Geliştirici Dizinleri (.ollama, .cache, .gradle, .npm)
        let dotDirs: [(path: String, title: String, detail: String)] = [
            (home + "/.ollama", "Ollama Yerel Model Deposu", "Yerel LLM model ağırlıkları ve katmanları"),
            (home + "/.cache", "HuggingFace / PyTorch / Pip Önbelleği", "Python ve AI kütüphaneleri model önbelleği"),
            (home + "/.gradle", "Gradle Bağımlılık ve Sürüm Deposu", "Android / Java kütüphaneleri ve wrapper'lar"),
            (home + "/.npm", "NPM Paket Deposu", "Node.js global paket arşivleri"),
            (home + "/.yarn", "Yarn Paket Deposu", "Yarn paket arşivi ve çevrimdışı önbelleği")
        ]
        
        for d in dotDirs {
            if fileManager.fileExists(atPath: d.path) {
                let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: d.path))
                if size > 100_000_000 {
                    items.append(SystemDataBreakdownItem(
                        title: d.title,
                        path: d.path,
                        size: size,
                        category: "Gizli Geliştirici & AI Alanları",
                        detail: d.detail,
                        isPurgeable: true,
                        isSelected: false
                    ))
                }
            }
        }
        
        return items.sorted(by: { $0.size > $1.size })
    }
    
    private func checkLocalSnapshots() -> [String] {
        let task = Process()
        task.launchPath = "/usr/bin/tmutil"
        task.arguments = ["listlocalsnapshots", "/"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        guard (try? task.run()) != nil else { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }
        
        return output.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.contains("com.apple.TimeMachine") }
    }
    
    public func executeCleanCommand(command: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let task = Process()
                task.launchPath = "/bin/zsh"
                task.arguments = ["-c", command]
                do {
                    try task.run()
                    task.waitUntilExit()
                    continuation.resume(returning: task.terminationStatus == 0)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
