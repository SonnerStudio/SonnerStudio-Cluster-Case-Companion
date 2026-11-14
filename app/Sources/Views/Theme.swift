import SwiftUI

enum SolarisTheme {
    // Warme Obsidian- & Titanium-Oberflächen passend zu "SonnerStudio"
    static let canvasBg = Color(red: 0.047, green: 0.059, blue: 0.078)        // #0C0F14
    static let sidebarBg = Color(red: 0.063, green: 0.078, blue: 0.106)       // #10141B
    static let cardBg = Color(red: 0.086, green: 0.106, blue: 0.141)          // #161B24
    static let cardElevated = Color(red: 0.114, green: 0.137, blue: 0.184)    // #1D232F
    static let borderSubtle = Color.white.opacity(0.10)

    // Akzentfarben: SonnerStudio-Gelb (Studio/TB) & Cyan-Mint (Mini/Worker)
    static let amber = Color(red: 1.000, green: 0.831, blue: 0.000)           // #FFD400 SonnerStudio-Gelb
    static let amberGlow = Color(red: 1.000, green: 0.894, blue: 0.302)       // #FFE44D SonnerStudio-Hellgelb
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

/// Industrielle schräg gestrichelte gelb-schwarze Warnbereichsmarkierung (45°-Hazard-Stripes)
struct HazardStripesBar: View {
    var height: CGFloat = 8
    var stripeWidth: CGFloat = 10
    var cornerRadius: CGFloat = 4
    var opacity: Double = 0.90

    var body: some View {
        Canvas { context, size in
            let pitch = stripeWidth * 2
            let span = size.width + size.height
            var x: CGFloat = -size.height
            while x < span {
                var path = Path()
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + stripeWidth, y: size.height))
                path.addLine(to: CGPoint(x: x + stripeWidth + size.height, y: 0))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                path.closeSubpath()
                context.fill(path, with: .color(SolarisTheme.amber.opacity(opacity)))
                x += pitch
            }
        }
        .frame(height: height)
        .background(Color(red: 0.06, green: 0.07, blue: 0.09).opacity(opacity))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(SolarisTheme.amber.opacity(0.45), lineWidth: 0.8)
        )
    }
}

/// Kompaktes Industrie-Warnzonen-Banner mit oberen und unteren gelb-schwarzen Warnstreifen
struct IndustrialHazardBanner<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    var accent: Color = SolarisTheme.amber
    @ViewBuilder var trailing: () -> Trailing

    init(
        icon: String = "exclamationmark.triangle.fill",
        title: String,
        subtitle: String,
        accent: Color = SolarisTheme.amber,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.trailing = trailing
    }

    var body: some View {
        VStack(spacing: 0) {
            HazardStripesBar(height: 6, stripeWidth: 9, cornerRadius: 0, opacity: 0.92)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer(minLength: 8)
                trailing()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.92))
            HazardStripesBar(height: 6, stripeWidth: 9, cornerRadius: 0, opacity: 0.92)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.45), lineWidth: 1.1)
        )
    }
}
