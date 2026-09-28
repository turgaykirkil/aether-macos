import Foundation
import SwiftUI

public enum SafetyLevel: String, CaseIterable, Identifiable {
    case protectedActive = "protectedActive"
    case recentProject = "recentProject"
    case dormantProject = "dormantProject"
    case staleProject = "staleProject"
    case safeJunk = "safeJunk"
    case userReview = "userReview"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .protectedActive:
            return "Aktif Proje (Dokunulmaz)"
        case .recentProject:
            return "Son 14 Günde Aktif"
        case .dormantProject:
            return "30+ Gündür Dokunulmadı"
        case .staleProject:
            return "90+ Gündür Atıl (Güvenli)"
        case .safeJunk:
            return "Güvenli Çöp"
        case .userReview:
            return "İnceleme Gerekli"
        }
    }
    
    public var icon: String {
        switch self {
        case .protectedActive:
            return "shield.fill"
        case .recentProject:
            return "clock.fill"
        case .dormantProject:
            return "moon.fill"
        case .staleProject:
            return "trash.circle.fill"
        case .safeJunk:
            return "checkmark.shield.fill"
        case .userReview:
            return "exclamationmark.triangle.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .protectedActive:
            return Color.blue
        case .recentProject:
            return Color.cyan
        case .dormantProject:
            return Color.orange
        case .staleProject:
            return Color.green
        case .safeJunk:
            return Color.green
        case .userReview:
            return Color.yellow
        }
    }
    
    public var shouldAutoSelect: Bool {
        switch self {
        case .protectedActive, .recentProject, .userReview:
            return false // Asla otomatik seçilmez!
        case .dormantProject:
            return false
        case .staleProject, .safeJunk:
            return true
        }
    }
}
