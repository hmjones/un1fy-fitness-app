import SwiftUI

/// Warm neutrals, khaki highlights and quiet, rounded surfaces.
enum Theme {
    private static func adaptive(_ light: UIColor, _ dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static let background = adaptive(
        UIColor(red: 0.961, green: 0.953, blue: 0.929, alpha: 1),
        UIColor(red: 0.094, green: 0.098, blue: 0.090, alpha: 1)
    )
    static let cardBackground = adaptive(.white, UIColor(red: 0.141, green: 0.145, blue: 0.129, alpha: 1))
    static let cream = adaptive(
        UIColor(red: 0.129, green: 0.141, blue: 0.122, alpha: 1),
        UIColor(red: 0.957, green: 0.949, blue: 0.914, alpha: 1)
    )
    static let creamSecondary = adaptive(
        UIColor(red: 0.400, green: 0.420, blue: 0.376, alpha: 1),
        UIColor(red: 0.682, green: 0.698, blue: 0.643, alpha: 1)
    )
    static let creamTertiary = creamSecondary

    /// #C8BB96, the approved khaki accent. Use accentInk for text on it.
    static let accent = Color(red: 200 / 255, green: 187 / 255, blue: 150 / 255)
    static let accentInk = Color(red: 36 / 255, green: 44 / 255, blue: 24 / 255)
    static let accentText = adaptive(
        UIColor(red: 0.459, green: 0.404, blue: 0.278, alpha: 1),
        UIColor(red: 0.784, green: 0.733, blue: 0.588, alpha: 1)
    )
    static let flame = accentText
    static let success = Color(red: 0.298, green: 0.686, blue: 0.314)
    static let danger = Color(red: 0.871, green: 0.373, blue: 0.333)

    static let featuredBackground = accent
    static let featuredText = accentInk
    static let featuredTextSecondary = accentInk.opacity(0.8)
    static let featuredTextTertiary = accentInk.opacity(0.7)
    static let featuredFill = accentInk.opacity(0.08)
    static let neutralFill = adaptive(
        UIColor(red: 0.914, green: 0.925, blue: 0.875, alpha: 1),
        UIColor(red: 0.188, green: 0.208, blue: 0.169, alpha: 1)
    )
    static let cardBorder = adaptive(UIColor(white: 0, alpha: 0.03), UIColor(white: 1, alpha: 0.06))
    static let subtleDivider = adaptive(
        UIColor(red: 0.886, green: 0.894, blue: 0.855, alpha: 1),
        UIColor(red: 0.212, green: 0.224, blue: 0.188, alpha: 1)
    )
    static let cardShadow = Color.clear
    static let buttonForeground = background
    static let buttonBackground = cream
}

extension View {
    func softCard(cornerRadius: CGFloat = 24) -> some View {
        background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(Theme.cardBackground))
    }

    func featuredCard(cornerRadius: CGFloat = 24) -> some View {
        background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(Theme.featuredBackground))
    }
}
