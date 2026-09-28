import SwiftUI

public struct CleanItemRowView: View {
    let item: CleanItem
    let onToggle: () -> Void
    
    public init(item: CleanItem, onToggle: @escaping () -> Void) {
        self.item = item
        self.onToggle = onToggle
    }
    
    public var body: some View {
        let aiEval = AetherNeuralEngine.shared.evaluateArtifact(
            path: item.path,
            category: item.category,
            size: item.size,
            modDate: item.lastModified
        )
        
        return HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isSelected ? .cyan : .gray)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .semibold))
                    
                    // AI Neural Confidence Badge
                    HStack(spacing: 3) {
                        Image(systemName: aiEval.verdict.iconName)
                            .font(.system(size: 9))
                        Text("\(aiEval.confidencePercentage)% AI")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(aiEval.verdict.badgeColor.opacity(0.15))
                    .foregroundColor(aiEval.verdict.badgeColor)
                    .clipShape(Capsule())
                    
                    SafetyBadgeView(safety: item.safetyLevel)
                }
                
                Text(item.detail)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(item.category)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(4)
            
            Text(item.formattedSize)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .frame(minWidth: 70, alignment: .trailing)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .cornerRadius(10)
    }
}
