import Foundation

public final class ProjectActivityService {
    public static let shared = ProjectActivityService()
    private let fileManager = FileManager.default
    
    private init() {}
    
    public func getRunningProcessWorkingPaths() -> Set<String> {
        var paths: Set<String> = []
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-A", "-o", "command"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        if let _ = try? task.run() {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.contains("/Users/") {
                        // Satırdaki /Users/... yollarını yakala
                        let components = trimmed.components(separatedBy: " ")
                        for comp in components where comp.hasPrefix("/Users/") {
                            paths.insert(comp)
                        }
                    }
                }
            }
        }
        return paths
    }
    
    public func evaluateProjectSafety(projectDirectory: URL, runningPaths: Set<String>) -> (safety: SafetyLevel, lastModified: Date?, reason: String) {
        let pathStr = projectDirectory.path
        
        // 1. Çalışan süreç kontrolü (Aktif Process Kontrolü)
        for running in runningPaths {
            if running.contains(pathStr) || pathStr.contains(running) {
                return (.protectedActive, Date(), "Bu proje şu anda arka planda veya terminalde AKTİF olarak çalışıyor.")
            }
        }
        
        // 2. Git ve Dosya Değişiklik Tarihi
        var latestDate: Date? = nil
        
        // Git HEAD kontrolü
        let gitHead = projectDirectory.appendingPathComponent(".git/FETCH_HEAD")
        let gitLogs = projectDirectory.appendingPathComponent(".git/logs/HEAD")
        let gitIndex = projectDirectory.appendingPathComponent(".git/index")
        
        for gPath in [gitIndex, gitLogs, gitHead] {
            if let attrs = try? fileManager.attributesOfItem(atPath: gPath.path),
               let modDate = attrs[.modificationDate] as? Date {
                if latestDate == nil || modDate > latestDate! {
                    latestDate = modDate
                }
            }
        }
        
        // Eğer git yoksa projedeki en son dosya tarihini oku
        if latestDate == nil {
            if let attrs = try? fileManager.attributesOfItem(atPath: pathStr),
               let modDate = attrs[.modificationDate] as? Date {
                latestDate = modDate
            }
        }
        
        guard let date = latestDate else {
            return (.userReview, nil, "Tarih bilgisi alınamadı.")
        }
        
        let daysAgo = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        
        if daysAgo <= 7 {
            return (.protectedActive, date, "Son \(daysAgo) gün içinde üzerinde çalışıldı (Aktif Proje).")
        } else if daysAgo <= 21 {
            return (.recentProject, date, "\(daysAgo) gün önce kullanıldı (Yakın Proje).")
        } else if daysAgo <= 60 {
            return (.dormantProject, date, "\(daysAgo) gündür dokunulmadı (Uyuyan Proje).")
        } else {
            return (.staleProject, date, "\(daysAgo) gündür dokunulmadı (Atıl Proje - Güvenle Temizlenebilir).")
        }
    }
}
