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
    let isHovered: Bool
    let isHighlighted: Bool
    @ViewBuilder let content: () -> Content

    init(
        accent: Color? = nil,
        isHovered: Bool = false,
        isHighlighted: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.accent = accent
        self.isHovered = isHovered
        self.isHighlighted = isHighlighted
        self.content = content
    }

    var body: some View {
        let glowColor = accent ?? SolarisTheme.amber
        let glowActive = isHighlighted || isHovered
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isHovered ? SolarisTheme.cardElevated.opacity(0.88) : SolarisTheme.cardBg.opacity(0.84))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            isHighlighted
                                ? glowColor.opacity(0.82)
                                : (isHovered ? glowColor.opacity(0.68) : (accent?.opacity(0.38) ?? SolarisTheme.borderSubtle)),
                            lineWidth: glowActive ? 1.6 : 1.2
                        )
                )
        )
        .shadow(
            color: glowActive ? glowColor.opacity(isHighlighted ? 0.32 : 0.24) : Color.clear,
            radius: isHighlighted ? 16 : (isHovered ? 12 : 0),
            x: 0,
            y: 0
        )
        .animation(.easeInOut(duration: 0.16), value: isHovered)
        .animation(.easeInOut(duration: 0.16), value: isHighlighted)
    }
}

struct SolarisGlowModifier: ViewModifier {
    let accent: Color
    let isActive: Bool
    let isHovered: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let activeOrHovered = isActive || isHovered
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        isActive ? accent.opacity(0.88) : (isHovered ? accent.opacity(0.65) : Color.clear),
                        lineWidth: isActive ? 1.6 : (isHovered ? 1.2 : 0)
                    )
            )
            .shadow(
                color: activeOrHovered ? accent.opacity(isActive ? 0.36 : 0.25) : Color.clear,
                radius: isActive ? 14 : (isHovered ? 10 : 0),
                x: 0,
                y: 0
            )
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}

extension View {
    func solarisHighlightGlow(
        accent: Color = SolarisTheme.amber,
        isActive: Bool = false,
        isHovered: Bool = false,
        cornerRadius: CGFloat = 12
    ) -> some View {
        modifier(SolarisGlowModifier(accent: accent, isActive: isActive, isHovered: isHovered, cornerRadius: cornerRadius))
    }

    /// Programmweiter Shorttip/Tooltip beim Überfahren mit dem Mauszeiger (macOS .help + Solaris Hover-Leiste)
    func solarisShorttip(_ text: String, id: String, vm: ClusterViewModel) -> some View {
        modifier(SolarisShorttipModifier(text: text, id: id, vm: vm))
    }
}

struct SolarisShorttipModifier: ViewModifier {
    let text: String
    let id: String
    @ObservedObject var vm: ClusterViewModel

    func body(content: Content) -> some View {
        content
            .help(text)
            .accessibilityHint(text)
            .onHover { hovering in
                if hovering {
                    vm.setShorttip(text, id: id)
                } else {
                    vm.setShorttip(nil, id: id)
                }
            }
    }
}

/// Schwebender Solaris-Shorttip-Balken am unteren Rand, sobald der Mauszeiger über einem Bereich ruht
struct SolarisShorttipBanner: View {
    let text: String?

    var body: some View {
        if let text, !text.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(SolarisTheme.amberGlow)
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(SolarisTheme.textPrimary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(SolarisTheme.canvasBg.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(SolarisTheme.amber.opacity(0.65), lineWidth: 1)
                    )
            )
            .shadow(color: SolarisTheme.amber.opacity(0.25), radius: 10, x: 0, y: 4)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .padding(.bottom, 12)
            .padding(.horizontal, 20)
        }
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
