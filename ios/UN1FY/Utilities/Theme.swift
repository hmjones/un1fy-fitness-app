import SwiftUI

/// Design tokens for the clean monochrome aesthetic: a warm off-white canvas,
/// white cards with soft shadows, near-black featured boxes with white/gray
/// text, a single charcoal accent, and an orange streak flame as the only
/// pop of color.
enum Theme {
    private static func adaptive(_ light: UIColor, _ dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    // MARK: - Canvas

    /// Warm off-white app background.
    static let background = adaptive(
        UIColor(red: 0.961, green: 0.949, blue: 0.925, alpha: 1),
        UIColor(red: 0.086, green: 0.082, blue: 0.075, alpha: 1)
    )

    /// Card surface — pure white in light mode.
    static let cardBackground = adaptive(
        UIColor.white,
        UIColor(red: 0.133, green: 0.129, blue: 0.118, alpha: 1)
    )

    // MARK: - Ink (text)

    /// Primary text — soft near-black ink.
    static let cream = adaptive(
        UIColor(red: 0.125, green: 0.114, blue: 0.102, alpha: 1),
        UIColor(red: 0.957, green: 0.941, blue: 0.914, alpha: 1)
    )

    static let creamSecondary = adaptive(
        UIColor(red: 0.125, green: 0.114, blue: 0.102, alpha: 0.55),
        UIColor(red: 0.957, green: 0.941, blue: 0.914, alpha: 0.55)
    )

    static let creamTertiary = adaptive(
        UIColor(red: 0.125, green: 0.114, blue: 0.102, alpha: 0.35),
        UIColor(red: 0.957, green: 0.941, blue: 0.914, alpha: 0.35)
    )

    // MARK: - Accents

    /// Primary accent — charcoal ink (flips to off-white in dark mode).
    static let accent = adaptive(
        UIColor(red: 0.125, green: 0.114, blue: 0.102, alpha: 1),
        UIColor(red: 0.957, green: 0.941, blue: 0.914, alpha: 1)
    )

    /// Streak flame orange — the app's single pop of color.
    static let flame = adaptive(
        UIColor(red: 0.976, green: 0.451, blue: 0.086, alpha: 1),
        UIColor(red: 1.0, green: 0.541, blue: 0.196, alpha: 1)
    )

    static let success = Color(red: 0.298, green: 0.686, blue: 0.314)

    static let danger = Color(red: 0.871, green: 0.373, blue: 0.333)

    // MARK: - Featured boxes

    /// Near-black featured box (flips to off-white in dark mode so it still stands out).
    static let featuredBackground = adaptive(
        UIColor(red: 0.098, green: 0.094, blue: 0.086, alpha: 1),
        UIColor(red: 0.957, green: 0.941, blue: 0.914, alpha: 1)
    )

    /// Primary text on a featured box.
    static let featuredText = adaptive(
        UIColor(red: 0.980, green: 0.973, blue: 0.961, alpha: 1),
        UIColor(red: 0.098, green: 0.094, blue: 0.086, alpha: 1)
    )

    static let featuredTextSecondary = adaptive(
        UIColor(red: 0.980, green: 0.973, blue: 0.961, alpha: 0.62),
        UIColor(red: 0.098, green: 0.094, blue: 0.086, alpha: 0.55)
    )

    static let featuredTextTertiary = adaptive(
        UIColor(red: 0.980, green: 0.973, blue: 0.961, alpha: 0.38),
        UIColor(red: 0.098, green: 0.094, blue: 0.086, alpha: 0.35)
    )

    /// Subtle fill for tiles, chips, and icon circles sitting on a featured box.
    static let featuredFill = adaptive(
        UIColor(white: 1, alpha: 0.12),
        UIColor(white: 0, alpha: 0.07)
    )

    // MARK: - Neutral fill

    /// Light neutral gray for icon tiles, image placeholders, and avatar fallbacks.
    static let neutralFill = adaptive(
        UIColor(red: 0.925, green: 0.910, blue: 0.882, alpha: 1),
        UIColor(red: 0.196, green: 0.188, blue: 0.173, alpha: 1)
    )

    // MARK: - Lines & shadows

    static let cardBorder = adaptive(
        UIColor(white: 0, alpha: 0.04),
        UIColor(white: 1, alpha: 0.07)
    )

    static let subtleDivider = adaptive(
        UIColor(white: 0, alpha: 0.07),
        UIColor(white: 1, alpha: 0.08)
    )

    /// Soft drop shadow under white cards.
    static let cardShadow = adaptive(
        UIColor(red: 0.35, green: 0.30, blue: 0.22, alpha: 0.08),
        UIColor(white: 0, alpha: 0.35)
    )

    // MARK: - Buttons

    static let buttonForeground = adaptive(
        UIColor.white,
        UIColor(red: 0.086, green: 0.082, blue: 0.075, alpha: 1)
    )

    /// Primary button — soft charcoal ink pill.
    static let buttonBackground = adaptive(
        UIColor(red: 0.137, green: 0.125, blue: 0.110, alpha: 1),
        UIColor(red: 0.957, green: 0.941, blue: 0.914, alpha: 1)
    )
}

extension View {
    /// White card with a soft drop shadow and a hairline edge (for dark-mode definition).
    func softCard(cornerRadius: CGFloat = 20) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
                .shadow(color: Theme.cardShadow, radius: 14, x: 0, y: 6)
        )
    }

    /// Near-black featured box with big rounded corners and a soft shadow.
    func featuredCard(cornerRadius: CGFloat = 20) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Theme.featuredBackground)
                .shadow(color: Theme.cardShadow, radius: 14, x: 0, y: 6)
        )
    }
}
