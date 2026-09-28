import Foundation
import SwiftUI

public enum ScanCategory: String, CaseIterable, Identifiable {
    case aiCore = "aiCore"
    case dashboard = "dashboard"
    case systemData = "systemData"
    case appUninstaller = "appUninstaller"
    case orphanedLeftovers = "orphanedLeftovers"
    case aiAndDev = "aiAndDev"
    case memoryBooster = "memoryBooster"
    case largeFiles = "largeFiles"
    
    public var id: String { rawValue }
    
    public func localizedTitle(lang: AppLanguage) -> String {
        switch self {
        case .aiCore:
            return lang == .turkish ? "Aether Yapay Zeka Çekirdeği" : "Aether AI Neural Core"
        case .dashboard:
            return lang == .turkish ? "Genel Bakış" : "Dashboard Overview"
        case .systemData:
            return lang == .turkish ? "Sistem Verileri (110+ GB)" : "System Data Deep Inspector"
        case .appUninstaller:
            return lang == .turkish ? "Uygulama Kaldırıcı" : "App Uninstaller"
        case .orphanedLeftovers:
            return lang == .turkish ? "Silinmiş Uygulama Artıkları" : "Orphaned Leftovers"
        case .aiAndDev:
            return lang == .turkish ? "AI & Geliştirici Temizliği" : "AI & Dev Cleaner"
        case .memoryBooster:
            return lang == .turkish ? "AI & Dev RAM Booster" : "AI & Dev RAM Booster"
        case .largeFiles:
            return lang == .turkish ? "Büyük & Eski Dosyalar" : "Large & Old Files"
        }
    }
    
    public var title: String {
        localizedTitle(lang: LanguageManager.shared.currentLanguage)
    }
    
    public var iconName: String {
        switch self {
        case .aiCore:
            return "brain.head.profile"
        case .dashboard:
            return "gauge.with.needle.fill"
        case .systemData:
            return "internaldrive.fill"
        case .appUninstaller:
            return "trash.fill"
        case .orphanedLeftovers:
            return "ghost.fill"
        case .aiAndDev:
            return "cpu.fill"
        case .memoryBooster:
            return "bolt.shield.fill"
        case .largeFiles:
            return "doc.badge.gearshape.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .aiCore:
            return .purple
        case .dashboard:
            return .cyan
        case .systemData:
            return .pink
        case .appUninstaller:
            return .indigo
        case .orphanedLeftovers:
            return .orange
        case .aiAndDev:
            return .teal
        case .memoryBooster:
            return .yellow
        case .largeFiles:
            return .blue
        }
    }
}
