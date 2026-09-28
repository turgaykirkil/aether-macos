import Foundation

public final class OrphanedAppService {
    public static let shared = OrphanedAppService()
    private let fileManager = FileManager.default
    
    // Apple ve macOS Çekirdek Sistem Kütüphane İsimleri (Asla artık olarak işaretlenmemeli)
    private let systemWhitelistedPrefixes: Set<String> = [
        "com.apple.",
        "apple",
        "system",
        "spotlight",
        "siri",
        "safari",
        "finder",
        "dock",
        "keychain",
        "addressbook",
        "caldav",
        "callhistory",
        "cloud",
        "icloud",
        "mobilesync",
        "quicklook",
        "coredata",
        "webkit",
        "mediaplayer",
        "itunes",
        "music",
        "photos",
        "mail",
        "messages",
        "facetime",
        "preview",
        "textedit",
        "terminal",
        "console",
        "disk utility",
        "activity monitor",
        "app store",
        "appplaceholdersyncd",
        "askpermission",
        "animoji",
        "bluetooth",
        "wifi",
        "screentime",
        "speech",
        "sound",
        "syncservices",
        "timezone",
        "universalaccess",
        "useractivity",
        "windowmanager",
        "accounts",
        "reminders",
        "notes",
        "freeform",
        "shortcuts",
        "weather",
        "stocks",
        "clock",
        "calculator",
        "maps",
        "news",
        "podcasts",
        "tv",
        "books",
        "home"
    ]
    
    // CLI ve Geliştirici Terminal Araçları (Bir .app paketi olmasa da aktif kullanılan kritik araçlar)
    private let cliAndDevToolsWhitelist: Set<String> = [
        "cloudflared",
        "cloudflare",
        "homebrew",
        "brew",
        "docker",
        "colima",
        "orbstack",
        "podman",
        "git",
        "gh",
        "node",
        "npm",
        "yarn",
        "pnpm",
        "bun",
        "deno",
        "pip",
        "python",
        "poetry",
        "conda",
        "miniconda",
        "mamba",
        "cargo",
        "rust",
        "rustup",
        "golang",
        "go",
        "redis",
        "postgres",
        "postgresql",
        "mysql",
        "sqlite",
        "sqlite3",
        "mongodb",
        "supabase",
        "nginx",
        "caddy",
        "apache",
        "gcloud",
        "google-cloud-sdk",
        "aws",
        "azure",
        "terraform",
        "terragrunt",
        "packer",
        "vault",
        "ngrok",
        "localtunnel",
        "tmux",
        "zsh",
        "bash",
        "fish",
        "oh-my-zsh",
        "starship",
        "gnupg",
        "gpg",
        "ssh",
        "antigravity",
        "cursor",
        "vscode",
        "code",
        "zed",
        "neovim",
        "nvim",
        "emacs"
    ]
    
    private init() {}
    
    public func scanOrphanedItems(installedApps: [AppBundleItem]) async -> [CleanItem] {
        var orphans: [CleanItem] = []
        let home = NSHomeDirectory()
        
        // 1. Tüm kurulu uygulamaların Bundle ID ve İsim Listesini Topla
        var installedSignatures: Set<String> = []
        for app in installedApps {
            installedSignatures.insert(app.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
            let bId = app.bundleIdentifier.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if !bId.isEmpty {
                installedSignatures.insert(bId)
            }
        }
        
        // Sistem uygulamalarının da imzalarını ekle (/System/Applications)
        if let sysApps = try? fileManager.contentsOfDirectory(at: URL(fileURLWithPath: "/System/Applications"), includingPropertiesForKeys: nil) {
            for url in sysApps where url.pathExtension.lowercased() == "app" {
                let name = url.deletingPathExtension().lastPathComponent.lowercased()
                installedSignatures.insert(name)
                if let bundle = Bundle(url: url), let bId = bundle.bundleIdentifier?.lowercased() {
                    installedSignatures.insert(bId)
                }
            }
        }
        
        // Sistemdeki CLI ikililerini tespit et (/opt/homebrew/bin, /usr/local/bin, ~/.cargo/bin vb.)
        let binaryDirs = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", home + "/.cargo/bin", home + "/.local/bin"]
        for bDir in binaryDirs {
            if let binContents = try? fileManager.contentsOfDirectory(atPath: bDir) {
                for bin in binContents {
                    installedSignatures.insert(bin.lowercased())
                }
            }
        }
        
        // 2. Taranacak Kütüphane Dizinleri
        let targetLibraryDirs: [(dir: String, category: String)] = [
            (home + "/Library/Application Support", "Application Support Kalıntısı"),
            (home + "/Library/Caches", "Önbellek (Cache) Kalıntısı"),
            (home + "/Library/Saved Application State", "Kayıtlı Durum (Saved State)"),
            (home + "/Library/WebKit", "WebKit Kalıntısı"),
            (home + "/Library/HTTPStorages", "HTTP Depolama Kalıntısı")
        ]
        
        for (dirPath, category) in targetLibraryDirs {
            guard fileManager.fileExists(atPath: dirPath) else { continue }
            guard let contents = try? fileManager.contentsOfDirectory(atPath: dirPath) else { continue }
            
            for item in contents {
                if item.hasPrefix(".") { continue }
                
                let lowerItem = item.lowercased()
                let cleanItemName = lowerItem
                    .replacingOccurrences(of: ".savedstate", with: "")
                    .replacingOccurrences(of: ".plist", with: "")
                
                // 1. Sistem beyaz listesinde var mı kontrol et
                var isSystem = false
                for prefix in systemWhitelistedPrefixes {
                    if cleanItemName == prefix || cleanItemName.hasPrefix(prefix) || cleanItemName.contains(prefix) {
                        isSystem = true
                        break
                    }
                }
                if isSystem { continue }
                
                // 2. CLI veya Geliştirici Aracı beyaz listesinde var mı?
                var isDevTool = false
                for devTool in cliAndDevToolsWhitelist {
                    if cleanItemName == devTool || cleanItemName.contains(devTool) || devTool.contains(cleanItemName) {
                        isDevTool = true
                        break
                    }
                }
                if isDevTool { continue }
                
                // 3. Şu anda yüklü olan GUI uygulamalarından veya CLI binary'lerinden biriyle eşleşiyor mu?
                var isCurrentlyInstalled = false
                for sig in installedSignatures {
                    if cleanItemName == sig || cleanItemName.contains(sig) || sig.contains(cleanItemName) {
                        isCurrentlyInstalled = true
                        break
                    }
                }
                if isCurrentlyInstalled { continue }
                
                // 4. Eğer yüklü değilse ve sistem dosyası/CLI aracı değilse -> YETİM ARTIK!
                let fullPath = dirPath + "/" + item
                let size = DeletionService.shared.calculateSize(of: URL(fileURLWithPath: fullPath))
                
                if size > 100_000 { // 100 KB+ olanları listele
                    var isDir: ObjCBool = false
                    fileManager.fileExists(atPath: fullPath, isDirectory: &isDir)
                    
                    let attrs = try? fileManager.attributesOfItem(atPath: fullPath)
                    let modDate = attrs?[.modificationDate] as? Date
                    
                    // Son değiştirilme tarihine göre Güvenlik Seviyesi
                    var isRecent = false
                    var daysAgo = 999
                    if let date = modDate {
                        daysAgo = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
                        if daysAgo < 30 {
                            isRecent = true
                        }
                    }
                    
                    let safety: SafetyLevel = isRecent ? .userReview : .safeJunk
                    let shouldAutoSelect = !isRecent
                    let detailMsg = isRecent ?
                        "⚠️ Dikkat: Son \(daysAgo) gün içinde kullanılmış/değiştirilmiş. Bir arka plan veya CLI servisi olabilir. Yol: \(fullPath)" :
                        "Silinmiş eski uygulamanın \(category) kalıntısı (\(daysAgo) gündür dokunulmadı). Yol: \(fullPath)"
                    
                    orphans.append(CleanItem(
                        name: item,
                        path: fullPath,
                        size: size,
                        category: category,
                        detail: detailMsg,
                        isDirectory: isDir.boolValue,
                        isSelected: shouldAutoSelect,
                        lastModified: modDate,
                        safetyLevel: safety
                    ))
                }
            }
        }
        
        return orphans.sorted(by: { $0.size > $1.size })
    }
}
