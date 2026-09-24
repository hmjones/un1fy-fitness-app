import SwiftUI

struct StatsView: View {
    let store: MemberStore
    @State private var appeared: Bool = false
    @State private var commentsPost: FeedPost?
    @State private var sharePost: FeedPost?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection
                if store.isMindbodyConnected {
                    ProgressOverview(store: store)
                    ProgressBadgesSection(store: store)
                    DisclosureGroup("More about your progress") {
                        VStack(spacing: 20) {
                            monthComparisonCard
                            heatMapSection
                            classBreakdownSection
                            personalRecordsSection
                        }
                        .padding(.top, 16)
                    }
                    .font(.headline)
                    .foregroundStyle(Theme.cream)
                    myActivitySection
                } else {
                    notConnectedCard
                    ProgressBadgesSection(store: store)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Theme.background.ignoresSafeArea())
        .refreshable {
            await store.refreshData()
        }
        .sheet(item: $commentsPost) { post in
            FeedCommentsSheet(feed: store.feed, post: post)
        }
        .sheet(item: $sharePost) { post in
            ShareActivityView(
                post: post,
                streak: store.profile.currentStreak,
                totalClasses: store.profile.totalClasses
            )
        }
        .task {
            if store.feed.posts.isEmpty {
                await store.feed.refresh()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    /// The member's own posts, in the same format as the community feed.
    /// Matched via `isOwnPost` so posts keyed by a duplicate studio client id
    /// (e.g. created by the server job) still show up.
    private var myPosts: [FeedPost] {
        guard store.feed.clientId != nil else { return [] }
        return store.feed.posts.filter { store.feed.isOwnPost($0) }
    }

    private var myActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Activity")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.cream)

            if store.feed.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Theme.creamTertiary)
                    Spacer()
                }
                .padding(.vertical, 24)
            } else if myPosts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "figure.run")
                        .font(.title3)
                        .foregroundStyle(Theme.creamTertiary)
                    Text("No activity yet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.creamSecondary)
                    Text("Your completed classes will show up here automatically.")
                        .font(.caption)
                        .foregroundStyle(Theme.creamTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .softCard()
            } else {
                ForEach(myPosts) { post in
                    FeedPostCard(
                        post: post,
                        currentClientId: store.feed.clientId,
                        canInteract: store.feed.canInteract,
                        onLike: {
                            Task { await store.feed.toggleLike(post: post) }
                        },
                        onOpenComments: {
                            commentsPost = post
                        },
                        onShare: {
                            sharePost = post
                        }
                    )
                }
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private var headerSection: some View {
        PageIntroduction(eyebrow: "Your progress", title: "Showing up adds up.", subtitle: "Every class is another step forward.")
    }

    private var notConnectedCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 44))
                .foregroundStyle(Theme.creamTertiary)
            Text("No Stats Yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.cream)
            Text("Connect your Mindbody account from the Home tab to see your attendance, streaks, and personal records.")
                .font(.subheadline)
                .foregroundStyle(Theme.creamSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .softCard()
        .opacity(appeared ? 1 : 0)
    }

    private var monthComparisonCard: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("This Month")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.creamSecondary)
                Text("\(store.profile.classesThisMonth)")
                    .font(.system(.title, weight: .bold))
                    .foregroundStyle(Theme.cream)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Theme.subtleDivider)
                .frame(width: 1, height: 40)

            VStack(spacing: 4) {
                Text("Last Month")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.creamSecondary)
                Text("\(store.profile.classesLastMonth)")
                    .font(.system(.title, weight: .bold))
                    .foregroundStyle(Theme.cream)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Theme.subtleDivider)
                .frame(width: 1, height: 40)

            VStack(spacing: 4) {
                Text("Trend")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.creamSecondary)
                HStack(spacing: 4) {
                    Image(systemName: store.monthComparisonDelta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption.weight(.bold))
                    Text("\(abs(store.monthComparisonDelta))")
                        .font(.system(.title, weight: .bold))
                }
                .foregroundStyle(store.monthComparisonDelta >= 0 ? Theme.success : Theme.danger)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .softCard()
        .opacity(appeared ? 1 : 0)
    }

    private var heatMapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Attendance")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.cream)

            HeatMapGrid(store: store)
        }
        .padding(20)
        .softCard()
        .opacity(appeared ? 1 : 0)
    }

    private var classBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Class Type")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.cream)

            ForEach(ClassType.allCases) { type in
                HStack(spacing: 14) {
                    Image(systemName: type.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.cream)
                        .frame(width: 38, height: 38)
                        .background(Theme.neutralFill)
                        .clipShape(.rect(cornerRadius: 12))

                    Text(type.rawValue)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Theme.cream)

                    Spacer()

                    Text("\(store.classCount(for: type))")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.cream)

                    Text("classes")
                        .font(.caption)
                        .foregroundStyle(Theme.creamSecondary)
                }
            }
        }
        .padding(20)
        .softCard()
        .opacity(appeared ? 1 : 0)
    }

    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Records")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.featuredText)

            HStack(spacing: 12) {
                RecordCard(icon: "flame.fill", value: "\(store.profile.longestStreak)", label: "Longest Streak", unit: "days", iconColor: Theme.featuredText)
                RecordCard(icon: "calendar", value: "\(store.profile.mostClassesInMonth)", label: "Best Month", unit: "classes")
            }
            HStack(spacing: 12) {
                RecordCard(icon: "star.fill", value: "\(store.profile.totalClasses)", label: "Total Classes", unit: "all time")
                RecordCard(icon: "trophy.fill", value: "\(store.badges.filter { $0.isUnlocked }.count)", label: "Badges", unit: "earned")
            }
        }
        .padding(20)
        .featuredCard()
        .opacity(appeared ? 1 : 0)
    }
}

struct RecordCard: View {
    let icon: String
    let value: String
    let label: String
    let unit: String
    var iconColor: Color = Theme.featuredTextSecondary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(Theme.featuredText)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.featuredTextSecondary)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(Theme.featuredTextTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.featuredFill)
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }
}

struct HeatMapGrid: View {
    let store: MemberStore
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)
    private let calendar = Calendar.current
    private let weeks = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Theme.creamTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(allDays, id: \.self) { date in
                    let count = store.attendanceForDate(date)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(heatColor(count: count))
                        .aspectRatio(1, contentMode: .fit)
                }
            }

            HStack(spacing: 4) {
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.creamTertiary)
                ForEach(0..<4, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatColor(count: level))
                        .frame(width: 10, height: 10)
                }
                Text("More")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.creamTertiary)
            }
            .padding(.top, 4)
        }
    }

    private var allDays: [Date] {
        let today = Date()
        let totalDays = weeks * 7
        var days: [Date] = []
        for i in stride(from: totalDays - 1, through: 0, by: -1) {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                days.append(date)
            }
        }
        return days
    }

    private func heatColor(count: Int) -> Color {
        switch count {
        case 0: return Theme.neutralFill
        case 1: return Theme.accent.opacity(0.30)
        case 2: return Theme.accent.opacity(0.60)
        default: return Theme.accent.opacity(0.92)
        }
    }
}
