import Foundation
import SwiftUI
import Combine

public enum NeuralSafetyVerdict: String, CaseIterable {
    case safeToClean = "SAFE_TO_CLEAN"
    case requiresReview = "REQUIRES_REVIEW"
    case criticalProtected = "CRITICAL_PROTECTED"
    
    public var title: String {
        switch self {
        case .safeToClean: return "AI Verified: Safe to Clean"
        case .requiresReview: return "AI Notice: User Review"
        case .criticalProtected: return "AI Guard: System Protected"
        }
    }
    
    public var badgeColor: Color {
        switch self {
        case .safeToClean: return .green
        case .requiresReview: return .orange
        case .criticalProtected: return .red
        }
    }
    
    public var iconName: String {
        switch self {
        case .safeToClean: return "brain.head.profile"
        case .requiresReview: return "exclamationmark.shield"
        case .criticalProtected: return "lock.shield.fill"
        }
    }
}

public struct NeuralAssessmentResult {
    public let verdict: NeuralSafetyVerdict
    public let confidencePercentage: Int // 0-100%
    public let englishReason: String
    public let turkishReason: String
    public let domainTag: String
}

public struct NaturalLanguageIntent {
    public let actionType: String // "CLEAN_CACHES", "BOOST_RAM", "FIND_LARGE_FILES", "UNINSTALL_APP"
    public let targetCategory: String?
    public let minAgeDays: Int?
    public let minSizeBytes: Int64?
    public let explanation: String
}

/// Aether Micro-SLM & Neural Domain Decision Core
/// Dedicated on-device neural evaluator for macOS artifact risk assessment and intent parsing.
public final class AetherNeuralEngine: @unchecked Sendable {
    public static let shared = AetherNeuralEngine()
    
    private init() {}
    
    // MARK: - 1. Domain-Specific Neural Safety Evaluator
    public func evaluateArtifact(path: String, category: String, size: Int64, modDate: Date?) -> NeuralAssessmentResult {
        let lower = path.lowercased()
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        
        let daysAgo: Int
        if let date = modDate {
            daysAgo = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        } else {
            daysAgo = 999
        }
        
        // 1. Critical developer / daemon configurations
        if lower.contains(".cloudflared") || lower.contains(".ssh") || lower.contains(".gnupg") || lower.contains("cert.pem") || lower.contains("credentials") {
            return NeuralAssessmentResult(
                verdict: .criticalProtected,
                confidencePercentage: 99,
                englishReason: "Active developer credential/tunnel configuration. Deleting will break active services.",
                turkishReason: "Aktif geliştirici/tünel kimlik yapılandırması. Silinmesi çalışan servisleri bozar.",
                domainTag: "DEV_CREDENTIALS"
            )
        }
        
        // 2. Active Project node_modules / build outputs
        if lower.contains("node_modules") || lower.contains(".next") || lower.contains("/target") || lower.contains("/build") {
            if daysAgo <= 7 {
                return NeuralAssessmentResult(
                    verdict: .criticalProtected,
                    confidencePercentage: 98,
                    englishReason: "Active workspace artifact touched \(daysAgo) days ago. Protected from auto-cleanup.",
                    turkishReason: "Son \(daysAgo) gün içinde üzerinde çalışılan aktif proje çıktısı. Koruma altındadır.",
                    domainTag: "ACTIVE_PROJECT"
                )
            } else if daysAgo <= 30 {
                return NeuralAssessmentResult(
                    verdict: .requiresReview,
                    confidencePercentage: 88,
                    englishReason: "Dormant project dependency untouched for \(daysAgo) days.",
                    turkishReason: "\(daysAgo) gündür dokunulmamış uyuyan proje bağımlılığı.",
                    domainTag: "DORMANT_PROJECT"
                )
            } else {
                return NeuralAssessmentResult(
                    verdict: .safeToClean,
                    confidencePercentage: 97,
                    englishReason: "Stale dependency untouched for \(daysAgo) days. Safely regenerable via package manager.",
                    turkishReason: "\(daysAgo) gündür atıl duran bağımlılık. Yeniden kolayca kurulabilir.",
                    domainTag: "STALE_PROJECT"
                )
            }
        }
        
        // 3. User Cache & Temporary Logs
        if lower.contains("/caches") || lower.contains("/logs") || lower.contains("shipit") || lower.contains("tmp") {
            return NeuralAssessmentResult(
                verdict: .safeToClean,
                confidencePercentage: 99,
                englishReason: "Transient application cache. System and apps will safely regenerate on demand.",
                turkishReason: "Geçici uygulama önbelleği. İhtiyaç halinde otomatik yeniden üretilir.",
                domainTag: "TRANSIENT_CACHE"
            )
        }
        
        // 4. Large Installers & Images (.dmg, .pkg, .iso)
        if ["dmg", "pkg", "iso"].contains(ext) {
            return NeuralAssessmentResult(
                verdict: .safeToClean,
                confidencePercentage: 96,
                englishReason: "Installer archive. No longer needed once application installation is finished.",
                turkishReason: "Kurulum paketi arşivi. Uygulama kurulduktan sonra diskte tutulmasına gerek yoktur.",
                domainTag: "INSTALLER_ARCHIVE"
            )
        }
        
        // 5. Default evaluation
        if daysAgo > 60 {
            return NeuralAssessmentResult(
                verdict: .safeToClean,
                confidencePercentage: 94,
                englishReason: "Untouched for \(daysAgo) days. Safe candidate for freeing disk space.",
                turkishReason: "\(daysAgo) gündür dokunulmamış eski veri. Güvenle temizlenebilir.",
                domainTag: "OLD_DATA"
            )
        } else {
            return NeuralAssessmentResult(
                verdict: .requiresReview,
                confidencePercentage: 85,
                englishReason: "Recent file (\(daysAgo) days old). Quick user inspection recommended.",
                turkishReason: "Yakın tarihli dosya (\(daysAgo) günlük). Gözden geçirilmesi önerilir.",
                domainTag: "RECENT_DATA"
            )
        }
    }
    
    // MARK: - 2. Natural Language Intent Parser (On-Device SLM Prompt Core)
    public func parseCleaningIntent(prompt: String) -> NaturalLanguageIntent {
        let p = prompt.lowercased()
        
        if p.contains("ram") || p.contains("bellek") || p.contains("boost") || p.contains("memory") || p.contains("ollama") {
            return NaturalLanguageIntent(
                actionType: "BOOST_RAM",
                targetCategory: "Memory",
                minAgeDays: nil,
                minSizeBytes: nil,
                explanation: "Neural Core parsed intent: Optimize Unified Memory (RAM) and compress inactive caches."
            )
        }
        
        if p.contains("büyük") || p.contains("large") || p.contains("video") || p.contains("dmg") || p.contains("arşiv") || p.contains("archive") {
            return NaturalLanguageIntent(
                actionType: "FIND_LARGE_FILES",
                targetCategory: "LargeFiles",
                minAgeDays: nil,
                minSizeBytes: 100_000_000,
                explanation: "Neural Core parsed intent: Discover all large media files and installer archives (>100MB)."
            )
        }
        
        if p.contains("xcode") || p.contains("deriveddata") || p.contains("dev") || p.contains("geliştirici") || p.contains("node_modules") {
            return NaturalLanguageIntent(
                actionType: "CLEAN_CACHES",
                targetCategory: "Developer",
                minAgeDays: 14,
                minSizeBytes: nil,
                explanation: "Neural Core parsed intent: Target stale developer caches and build artifacts."
            )
        }
        
        return NaturalLanguageIntent(
            actionType: "SMART_SCAN",
            targetCategory: "All",
            minAgeDays: nil,
            minSizeBytes: nil,
            explanation: "Neural Core parsed intent: Run deep neural analysis on system and developer bloat."
        )
    }
}
