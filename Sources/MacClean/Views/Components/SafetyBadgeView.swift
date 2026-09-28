import SwiftUI

public struct SafetyBadgeView: View {
    let safety: SafetyLevel
    
    public init(safety: SafetyLevel) {
        self.safety = safety
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: safety.icon)
                .font(.system(size: 9, weight: .bold))
            Text(safety.title)
                .font(.system(size: 10, weight: .bold))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(safety.color.opacity(0.15))
        .foregroundColor(safety.color)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(safety.color.opacity(0.3), lineWidth: 0.8)
        )
        .cornerRadius(5)
    }
}
