import Foundation

public enum DeletionMode: String, CaseIterable, Identifiable {
    case trash = "trash"
    case permanent = "permanent"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .trash:
            return "Çöp Kutusuna Taşı (Güvenli)"
        case .permanent:
            return "Kalıcı Olarak Sil (Hızlı)"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .trash:
            return "Dosyalar macOS Çöp Sepeti'ne gönderilir, istendiğinde geri alınabilir."
        case .permanent:
            return "Dosyalar diskten kalıcı olarak silinir ve anında yer açılır."
        }
    }
    
    public var icon: String {
        switch self {
        case .trash:
            return "trash.circle.fill"
        case .permanent:
            return "flame.circle.fill"
        }
    }
}
