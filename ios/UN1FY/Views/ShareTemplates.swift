import SwiftUI

/// The three share-card designs a member can pick from when sharing an
/// activity to socials.
enum ShareTemplate: Int, CaseIterable, Identifiable {
    case photo
    case logo
    case stats

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .photo: return "Photo"
        case .logo: return "Classic"
        case .stats: return "Stats"
        }
    }
}

/// Fixed (non-adaptive) colors for the exported share image so it renders
/// identically regardless of the device's light/dark appearance.
enum SharePalette {
    static let ink = Color(red: 0.098, green: 0.094, blue: 0.086)
    static let inkSecondary = Color(red: 0.098, green: 0.094, blue: 0.086).opacity(0.55)
    static let paper = Color(red: 0.961, green: 0.949, blue: 0.925)
    static let flame = Color(red: 0.976, green: 0.451, blue: 0.086)

    /// The design-time size of every template; rendered at 3x for export
    /// (1080 x 1350 px, a 4:5 portrait that works for feeds and stories).
    static let cardSize = CGSize(width: 360, height: 450)

    /// Friendly date for the share card, e.g. "Mon, Jul 14". Class times are
    /// stored as studio wall-clock tagged UTC, so format them in UTC.
    static func formattedDate(for post: FeedPost) -> String {
        if let classDate = post.classDate {
            return utcDateFormatter.string(from: classDate)
        }
        if let created = post.createdDate {
            return localDateFormatter.string(from: created)
        }
        return ""
    }

    private static let utcDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, MMM d"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    private static let localDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()
}

/// Template 1 — the attached class photo filling the frame with a dark
/// bottom gradient and white overlaid text. Falls back to a textured dark
/// card when the activity has no photo.
struct SharePhotoTemplateView: View {
    let post: FeedPost
    let photo: UIImage?

    var body: some View {
        ZStack {
            backgroundLayer

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.35), location: 0),
                    .init(color: .clear, location: 0.22),
                    .init(color: .clear, location: 0.55),
                    .init(color: .black.opacity(0.55), location: 0.8),
                    .init(color: .black.opacity(0.9), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 0) {
                Image("UN1FYWordmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 20)
                    .foregroundStyle(.white)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 8) {
                    Text(post.memberName)
                        .font(.system(size: 27, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(post.actionText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(SharePalette.formattedDate(for: post))
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(26)
        }
        .frame(width: SharePalette.cardSize.width, height: SharePalette.cardSize.height)
        .clipped()
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if let photo {
            Image(uiImage: photo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: SharePalette.cardSize.width, height: SharePalette.cardSize.height)
                .clipped()
        } else {
            ZStack {
                SharePalette.ink
                Image("UN1FYWordmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 420)
                    .foregroundStyle(.white.opacity(0.06))
                    .rotationEffect(.degrees(-18))
                    .offset(y: -40)
                RadialGradient(
                    colors: [.white.opacity(0.08), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 380
                )
            }
        }
    }
}

/// Template 2 — clean near-black card with the UN1FY logo up top and the
/// workout details in white and gray, matching the app's featured-box look.
struct ShareLogoTemplateView: View {
    let post: FeedPost

    var body: some View {
        ZStack {
            SharePalette.ink

            RadialGradient(
                colors: [.white.opacity(0.09), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 340
            )

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                Image("UN1FYLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 190)

                Spacer(minLength: 0)

                VStack(spacing: 12) {
                    Text(post.memberName)
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(post.actionText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.62))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 28)
                }

                Spacer(minLength: 0)

                detailChips

                Spacer(minLength: 0)

                Text(SharePalette.formattedDate(for: post))
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.38))
                    .padding(.bottom, 26)
            }
            .padding(.top, 34)
        }
        .frame(width: SharePalette.cardSize.width, height: SharePalette.cardSize.height)
        .clipped()
    }

    @ViewBuilder
    private var detailChips: some View {
        HStack(spacing: 10) {
            if let calories = post.calories, calories > 0 {
                chip(icon: "flame.fill", text: "\(calories) CAL", iconColor: SharePalette.flame)
            }
            if !post.classTimeString.isEmpty {
                chip(icon: "clock", text: post.classTimeString.uppercased(), iconColor: .white.opacity(0.62))
            }
        }
    }

    private func chip(icon: String, text: String, iconColor: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(iconColor)
            Text(text)
                .font(.system(size: 13, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.white.opacity(0.12))
        .clipShape(Capsule())
    }
}

/// Template 3 — minimal off-white card with huge black numbers: calories
/// (when available), current streak, and total classes.
struct ShareStatsTemplateView: View {
    let post: FeedPost
    let streak: Int
    let totalClasses: Int

    var body: some View {
        ZStack {
            SharePalette.paper

            VStack(alignment: .leading, spacing: 0) {
                Image("UN1FYWordmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 18)
                    .foregroundStyle(SharePalette.ink)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 24) {
                    if let calories = post.calories, calories > 0 {
                        statBlock(value: "\(calories)", label: "CALORIES BURNED")
                    }
                    statBlock(value: "\(streak)", label: "DAY STREAK", accessory: streakFlame)
                    statBlock(value: "\(totalClasses)", label: "TOTAL CLASSES")
                }

                Spacer(minLength: 0)

                Rectangle()
                    .fill(SharePalette.ink)
                    .frame(width: 44, height: 3)
                    .padding(.bottom, 12)

                Text(post.displayClassName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SharePalette.ink)
                Text(SharePalette.formattedDate(for: post))
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(SharePalette.inkSecondary)
                    .padding(.top, 3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(28)
        }
        .frame(width: SharePalette.cardSize.width, height: SharePalette.cardSize.height)
        .clipped()
    }

    private var streakFlame: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(SharePalette.flame)
    }

    private func statBlock(value: String, label: String) -> some View {
        statBlock(value: value, label: label, accessory: EmptyView())
    }

    private func statBlock(value: String, label: String, accessory: some View) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(value)
                    .font(.system(size: 52, weight: .black))
                    .foregroundStyle(SharePalette.ink)
                accessory
            }
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .tracking(2)
                .foregroundStyle(SharePalette.inkSecondary)
        }
    }
}
