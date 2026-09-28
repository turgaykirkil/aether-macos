import Foundation
import SwiftUI
import Combine

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case turkish = "tr"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .english: return "English"
        case .turkish: return "Türkçe"
        }
    }
    
    public var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .turkish: return "🇹🇷"
        }
    }
}

public final class LanguageManager: ObservableObject, @unchecked Sendable {
    public static let shared = LanguageManager()
    
    @Published public var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "Aether_Selected_Language")
        }
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "Aether_Selected_Language") ?? "en"
        self.currentLanguage = AppLanguage(rawValue: saved) ?? .english
    }
    
    public func localized(_ en: String, _ tr: String) -> String {
        return currentLanguage == .turkish ? tr : en
    }
}
