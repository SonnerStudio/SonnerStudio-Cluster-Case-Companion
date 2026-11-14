import SwiftUI

enum SolarisTheme {
    // Warme Obsidian- & Titanium-Oberflächen passend zu "SonnerStudio"
    static let canvasBg = Color(red: 0.047, green: 0.059, blue: 0.078)        // #0C0F14
    static let sidebarBg = Color(red: 0.063, green: 0.078, blue: 0.106)       // #10141B
    static let cardBg = Color(red: 0.086, green: 0.106, blue: 0.141)          // #161B24
    static let cardElevated = Color(red: 0.114, green: 0.137, blue: 0.184)    // #1D232F
    static let borderSubtle = Color.white.opacity(0.10)

    // Akzentfarben: Sonnen-Amber (Studio/TB) & Cyan-Mint (Mini/Worker)
    static let amber = Color(red: 0.961, green: 0.620, blue: 0.043)           // #F59E0B
    static let amberGlow = Color(red: 1.000, green: 0.720, blue: 0.220)
    static let mint = Color(red: 0.176, green: 0.831, blue: 0.749)            // #2DD4BF
    static let emerald = Color(red: 0.063, green: 0.725, blue: 0.506)         // #10B981
    static let coral = Color(red: 0.957, green: 0.369, blue: 0.369)           // #F45E5E

    static let textPrimary = Color(red: 0.95, green: 0.96, blue: 0.98)
    static let textSecondary = Color(red: 0.67, green: 0.72, blue: 0.80)

    // Große, gut lesbare Typografie
    static let heroTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 21, weight: .bold, design: .rounded)
    static let cardTitle = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let bodyLarge = Font.system(size: 15, weight: .regular, design: .default)
    static let bodyBold = Font.system(size: 15, weight: .semibold, design: .default)
    static let metricHuge = Font.system(size: 34, weight: .bold, design: .rounded).monospacedDigit()
    static let metricMedium = Font.system(size: 22, weight: .bold, design: .rounded).monospacedDigit()
    static let monoCode = Font.system(size: 14, weight: .medium, design: .monospaced)
}

struct SolarisCard<Content: View>: View {
    let accent: Color?
    @ViewBuilder let content: () -> Content

    init(accent: Color? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.accent = accent
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(SolarisTheme.cardBg.opacity(0.84))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accent?.opacity(0.38) ?? SolarisTheme.borderSubtle, lineWidth: 1.2)
                )
        )
    }
}
