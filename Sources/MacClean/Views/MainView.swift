import SwiftUI

public struct MainView: View {
    @EnvironmentObject var mainVM: MainViewModel
    @StateObject private var lang = LanguageManager.shared
    @AppStorage("Aether_Has_Seen_Intro_v2") private var hasSeenIntro: Bool = false
    @State private var showOnboarding: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                // App Brand Header
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color.purple, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.cyan.opacity(0.4), radius: 8, x: 0, y: 3)
                        
                        Image(systemName: "atom")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Aether")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            Text("AI")
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(colors: [Color.cyan, Color.purple], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        
                        Text("Neural macOS Optimizer")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Onboarding Guide Button
                    Button(action: {
                        showOnboarding = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                            Text("Intro")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.purple)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help(lang.localized("Aether 2.0 Intro & Vision", "Aether 2.0 Tanıtım ve Vizyon"))
                    
                    // Language Switcher Toggle Pill
                    Button(action: {
                        withAnimation {
                            lang.currentLanguage = (lang.currentLanguage == .english) ? .turkish : .english
                        }
                    }) {
                        Text("\(lang.currentLanguage.flag) \(lang.currentLanguage == .english ? "EN" : "TR")")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Change Language / Dili Değiştir")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
                Divider()
                
                // Navigation Items List
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Section 0: Aether AI Core (Featured SLM)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(lang.localized("ON-DEVICE NEURAL CORE", "YAPAY ZEKA ÇEKİRDEĞİ"))
                                .font(.system(size: 9.5, weight: .heavy))
                                .foregroundColor(.purple)
                                .padding(.horizontal, 14)
                                .padding(.top, 8)
                            
                            SidebarButton(
                                category: .aiCore,
                                selectedCategory: $mainVM.selectedCategory,
                                gradientColors: [Color.purple, Color.cyan],
                                badgeText: "SLM 0.5B",
                                badgeColor: .purple
                            )
                        }
                        
                        // Section 1: Temizlik & Analiz
                        VStack(alignment: .leading, spacing: 6) {
                            Text(lang.localized("CLEANUP & ANALYSIS", "TEMİZLİK & DERİN ANALİZ"))
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.8))
                                .padding(.horizontal, 14)
                            
                            SidebarButton(
                                category: .dashboard,
                                selectedCategory: $mainVM.selectedCategory,
                                gradientColors: [Color.cyan, Color.blue]
                            )
                            
                            SidebarButton(
                                category: .systemData,
                                selectedCategory: $mainVM.selectedCategory,
                                gradientColors: [Color.pink, Color.red],
                                badgeText: mainVM.formattedSystemDataBadge,
                                badgeColor: .pink
                            )
                            
                            SidebarButton(
                                category: .appUninstaller,
                                selectedCategory: $mainVM.selectedCategory,
                                gradientColors: [Color.indigo, Color.purple]
                            )
                            
                            SidebarButton(
                                category: .orphanedLeftovers,
                                selectedCategory: $mainVM.selectedCategory,
                                gradientColors: [Color.orange, Color.red]
                            )
                            
                            SidebarButton(
                                category: .aiAndDev,
                                selectedCategory: $mainVM.selectedCategory,
                                gradientColors: [Color.teal, Color.cyan],
                                badgeText: "ARMOR",
                                badgeColor: .cyan
                            )
                            
                            SidebarButton(
                                category: .largeFiles,
                                selectedCategory: $mainVM.selectedCategory,
                                gradientColors: [Color.blue, Color.indigo]
                            )
                        }
                        
                        // Section 2: Performans & Bellek
                        VStack(alignment: .leading, spacing: 6) {
                            Text(lang.localized("PERFORMANCE & MEMORY", "PERFORMANS & BELLEK"))
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.8))
                                .padding(.horizontal, 14)
                            
                            SidebarButton(
                                category: .memoryBooster,
                                selectedCategory: $mainVM.selectedCategory,
                                gradientColors: [Color.yellow, Color.orange],
                                badgeText: "TURBO",
                                badgeColor: .orange
                            )
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // Bottom Storage Meter Widget (Clean layout, non-clipped)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "internaldrive.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.cyan)
                            Text("Macintosh HD")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        Spacer()
                        Text("\(mainVM.formattedFreeDisk) \(lang.localized("Free", "Boş"))")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.18))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cyan, Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(8, geo.size.width * CGFloat(min(1.0, max(0.0, mainVM.usedDiskPercentage / 100.0)))), height: 6)
                                .shadow(color: Color.cyan.opacity(0.4), radius: 3, x: 0, y: 0)
                        }
                    }
                    .frame(height: 6)
                    
                    HStack {
                        Text("%\(String(format: "%.1f", mainVM.usedDiskPercentage)) \(lang.localized("Used", "Dolu"))")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(mainVM.formattedTotalDisk) \(lang.localized("Total", "Toplam"))")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.15))
                        .padding(.horizontal, 8)
                )
            }
            .frame(minWidth: 260, idealWidth: 280, maxWidth: 320)
            .background(.ultraThinMaterial)
        } detail: {
            Group {
                switch mainVM.selectedCategory {
                case .aiCore:
                    AetherAICoreView()
                case .dashboard:
                    DashboardView()
                case .systemData:
                    SystemDataView()
                case .appUninstaller:
                    AppUninstallerView()
                case .orphanedLeftovers:
                    OrphanedLeftoversView()
                case .aiAndDev:
                    DeveloperCleanerView()
                case .memoryBooster:
                    AIBoosterView()
                case .largeFiles:
                    LargeFilesView()
                }
            }
            .frame(minWidth: 720, minHeight: 580)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            if !hasSeenIntro {
                showOnboarding = true
                hasSeenIntro = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            AetherOnboardingView(isPresented: $showOnboarding)
        }
    }
}

// MARK: - Modern Sidebar Button Component
struct SidebarButton: View {
    let category: ScanCategory
    @Binding var selectedCategory: ScanCategory
    let gradientColors: [Color]
    var badgeText: String? = nil
    var badgeColor: Color = .blue
    
    @State private var isHovered = false
    
    var isSelected: Bool {
        selectedCategory == category
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedCategory = category
            }
        }) {
            HStack(spacing: 11) {
                // Vibrant Gradient Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 26, height: 26)
                        .shadow(color: gradientColors.first?.opacity(isSelected ? 0.4 : 0.15) ?? .clear, radius: 4, x: 0, y: 2)
                    
                    Image(systemName: category.iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(category.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .primary.opacity(0.85))
                
                Spacer()
                
                if let badge = badgeText, !badge.isEmpty {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(badgeColor.opacity(0.15))
                        .foregroundColor(badgeColor)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(
                        isSelected ?
                        Color.accentColor.opacity(0.15) :
                        (isHovered ? Color.primary.opacity(0.05) : Color.clear)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(
                        isSelected ? Color.accentColor.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
