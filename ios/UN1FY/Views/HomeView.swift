import SwiftUI

struct HomeView: View {
    let store: MemberStore
    @State private var appeared: Bool = false
    @State private var streakBounce: Int = 0
    @State private var commentsPost: FeedPost?
    @State private var sharePost: FeedPost?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                greetingSection
                if store.isMindbodyConnected {
                    if let issue = store.dataIssue {
                        dataIssueBanner(issue)
                    }
                    VStack(spacing: 12) {
                        streakBadge
                        quickStats
                    }
                    nextClassCard
                    bookClassButton
                } else {
                    mindbodyConnectionCard
                }
                communitySection
                motivationalQuote
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
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
            await AvatarStore.shared.loadIfNeeded()
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

    private var communitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Community")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.cream)

            if let promptPost = store.feed.photoPromptPost {
                FeedPhotoPromptCard(feed: store.feed, post: promptPost)
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            }

            if store.feed.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Theme.creamTertiary)
                    Spacer()
                }
                .padding(.vertical, 24)
            } else if store.feed.posts.isEmpty {
                feedEmptyState
            } else {
                ForEach(store.feed.posts) { post in
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
                        onShare: store.feed.isOwnPost(post)
                            ? { sharePost = post }
                            : nil
                    )
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: store.feed.photoPromptPost?.id)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    private func dataIssueBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundStyle(Theme.danger)
            VStack(alignment: .leading, spacing: 4) {
                Text("Some stats may be out of date")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.cream)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Theme.creamSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Theme.danger.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Theme.cardShadow, radius: 14, x: 0, y: 6)
        )
        .transition(.scale(scale: 0.97).combined(with: .opacity))
        .opacity(appeared ? 1 : 0)
    }

    private var feedEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.3.fill")
                .font(.title3)
                .foregroundStyle(Theme.creamTertiary)
            Text("No activity yet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.creamSecondary)
            Text("Completed classes will show up here automatically.")
                .font(.caption)
                .foregroundStyle(Theme.creamTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .softCard()
    }

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(store.profile.firstName.isEmpty ? "Hey there" : "Hey, \(store.profile.firstName)")
                    .font(.system(.largeTitle, weight: .bold))
                    .foregroundStyle(Theme.cream)
                Text(greetingTimeOfDay)
                    .font(.subheadline)
                    .foregroundStyle(Theme.creamSecondary)
            }
            Spacer()
            AvatarView(
                clientId: AvatarStore.shared.ownClientId,
                initials: avatarInitials,
                size: 48
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var avatarInitials: String {
        let initials = "\(store.profile.firstName.prefix(1))\(store.profile.lastName.prefix(1))"
        return initials.isEmpty ? "U" : initials.uppercased()
    }

    private var mindbodyConnectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if store.showConnectionSuccess {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.success)
                        .symbolEffect(.bounce, value: store.showConnectionSuccess)
                    Text("Connected!")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.cream)
                    Text("Your Mindbody account is synced.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.creamSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .transition(.scale.combined(with: .opacity))
            } else {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MINDBODY")
                            .font(.caption.weight(.bold))
                            .tracking(1.5)
                            .foregroundStyle(Theme.creamTertiary)

                        Text("Connect Your Account")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.cream)

                        Text(store.mindbodyConnectionMessage)
                            .font(.subheadline)
                            .foregroundStyle(Theme.creamSecondary)
                    }

                    Spacer()

                    Image(systemName: "link.badge.plus")
                        .font(.title2)
                        .foregroundStyle(Theme.cream)
                }
                .transition(.scale.combined(with: .opacity))

                if let error = store.mindbodyConnectionError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.footnote)
                        Text(error)
                            .font(.footnote)
                    }
                    .foregroundStyle(Theme.danger)
                }

                Button {
                    Task {
                        await store.connectMindbody()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if store.mindbodyConnectionState == .connecting {
                            ProgressView()
                                .tint(Theme.buttonForeground)
                        } else {
                            Image(systemName: "link")
                                .font(.body.weight(.semibold))
                        }

                        Text(store.mindbodyConnectionState == .connecting ? "Opening Mindbody…" : "Connect Mindbody")
                            .font(.headline)
                    }
                    .foregroundStyle(Theme.buttonForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.buttonBackground)
                    .clipShape(.rect(cornerRadius: 14))
                }
                .disabled(store.mindbodyConnectionState == .connecting)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                    Text("You'll sign in securely via Mindbody")
                        .font(.caption)
                }
                .foregroundStyle(Theme.creamTertiary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(store.showConnectionSuccess ? Theme.success.opacity(0.4) : Theme.cardBorder, lineWidth: 1)
                )
                .shadow(color: Theme.cardShadow, radius: 14, x: 0, y: 6)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.showConnectionSuccess)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    private var streakBadge: some View {
        HStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.flame)
                    .frame(width: 44, height: 44)
                    .background(Theme.featuredFill)
                    .clipShape(Circle())
                    .symbolEffect(.bounce, value: streakBounce)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(store.profile.currentStreak)")
                        .font(.system(.title, weight: .black))
                        .foregroundStyle(Theme.featuredText)
                    Text("day streak")
                        .font(.caption)
                        .foregroundStyle(Theme.featuredTextSecondary)
                }
            }
            Spacer()
            Text("Keep it up!")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.featuredTextSecondary)
        }
        .padding(20)
        .featuredCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                streakBounce += 1
            }
        }
    }

    private var quickStats: some View {
        HStack(spacing: 12) {
            StatPill(value: "\(store.classesThisWeek)", label: "This Week")
            StatPill(value: "\(store.profile.classesThisMonth)", label: "This Month")
            StatPill(value: "\(store.profile.totalClasses)", label: "All Time")
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    private var nextClassCard: some View {
        Group {
            if let next = store.upcomingClass {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("NEXT CLASS")
                            .font(.caption.weight(.bold))
                            .tracking(1.5)
                            .foregroundStyle(Theme.creamTertiary)
                        Spacer()
                        Image(systemName: next.classType.icon)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.cream)
                            .frame(width: 40, height: 40)
                            .background(Theme.neutralFill)
                            .clipShape(.rect(cornerRadius: 13))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(next.displayName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.cream)
                        HStack(spacing: 16) {
                            Label(formattedDate(next.date), systemImage: "calendar")
                            if !next.time.isEmpty {
                                Label(next.time, systemImage: "clock")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Theme.creamSecondary)

                        if !next.instructor.isEmpty {
                            Text("with \(next.instructor)")
                                .font(.subheadline)
                                .foregroundStyle(Theme.creamTertiary)
                        }
                    }
                }
                .padding(20)
                .softCard()
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    private var bookClassButton: some View {
        Button {
            store.openMindbody()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Book a Class")
                    .font(.headline)
            }
            .foregroundStyle(Theme.buttonForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.buttonBackground)
            .clipShape(.rect(cornerRadius: 18, style: .continuous))
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: false)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    private var motivationalQuote: some View {
        VStack(spacing: 8) {
            Image(systemName: "quote.opening")
                .font(.title3)
                .foregroundStyle(Theme.creamTertiary)
            Text(MotivationalQuotes.quoteForToday())
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.creamSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .opacity(appeared ? 1 : 0)
    }

    private var greetingTimeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning. Let's get after it." }
        if hour < 17 { return "Good afternoon. Time to move." }
        return "Good evening. End the day strong."
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayName = formatter.string(from: date)
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        return dayName
    }
}

struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(Theme.featuredText)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.featuredTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.featuredBackground)
                .shadow(color: Theme.cardShadow, radius: 14, x: 0, y: 6)
        )
    }
}
