import SwiftUI

public struct DeletionModePicker: View {
    @Binding var mode: DeletionMode
    
    public init(mode: Binding<DeletionMode>) {
        self._mode = mode
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Text("Silme Modu:")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Picker("", selection: $mode) {
                ForEach(DeletionMode.allCases) { item in
                    Label(item.title, systemImage: item.icon)
                        .tag(item)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 320)
            
            if mode == .permanent {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Kalıcı silme geri alınamaz!")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(6)
            }
        }
    }
}
