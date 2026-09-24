import SwiftUI

struct CommunityView: View {
    let store: MemberStore
    @State private var section: CommunitySection = .feed

    private enum CommunitySection: String, CaseIterable {
        case feed = "Feed", ranks = "Ranks", challenges = "Challenges"
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                PageIntroduction(eyebrow: "Your people", title: "Stronger together.", subtitle: "A little encouragement goes a long way.")
                Picker("Community section", selection: $section) {
                    ForEach(CommunitySection.allCases, id: \.self) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 16)

            switch section {
            case .feed:
                ScrollView {
                    CommunityFeedSection(store: store)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 32)
                }
                .refreshable { await store.feed.refresh() }
            case .ranks:
                LeaderboardView(memberStore: store, showsHeader: false)
            case .challenges:
                ChallengesView(store: store, showsHeader: false)
            }
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

/// Home and Community share the live feed and its existing actions.
struct CommunityFeedSection: View {
    let store: MemberStore
    var previewLimit: Int? = nil
    @State private var commentsPost: FeedPost?
    @State private var sharePost: FeedPost?

    private var posts: [FeedPost] {
        guard let previewLimit else { return store.feed.posts }
        return Array(store.feed.posts.prefix(previewLimit))
    }

    var body: some View {
        LazyVStack(spacing: 16) {
            if let prompt = store.feed.photoPromptPost {
                FeedPhotoPromptCard(feed: store.feed, post: prompt)
            }
            if store.feed.isLoading && store.feed.posts.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(24)
            } else if store.feed.posts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "person.2").font(.title2)
                    Text("No activity yet").font(.headline)
                    Text("Completed classes will show up here automatically.")
                        .font(.subheadline).multilineTextAlignment(.center)
                }
                .foregroundStyle(Theme.creamSecondary)
                .frame(maxWidth: .infinity)
                .padding(24)
                .softCard()
            } else {
                ForEach(posts) { post in
                    FeedPostCard(
                        post: post,
                        currentClientId: store.feed.clientId,
                        canInteract: store.feed.canInteract,
                        onLike: { Task { await store.feed.toggleLike(post: post) } },
                        onOpenComments: { commentsPost = post },
                        onShare: store.feed.isOwnPost(post) ? { sharePost = post } : nil
                    )
                }
            }
        }
        .sheet(item: $commentsPost) { post in
            FeedCommentsSheet(feed: store.feed, post: post)
        }
        .sheet(item: $sharePost) { post in
            ShareActivityView(post: post, streak: store.profile.currentStreak, totalClasses: store.profile.totalClasses)
        }
        .task {
            await AvatarStore.shared.loadIfNeeded()
            if store.feed.posts.isEmpty { await store.feed.refresh() }
        }
    }
}

struct PageIntroduction: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold)).tracking(1.5)
                .foregroundStyle(Theme.creamSecondary)
            Text(title)
                .font(.system(.largeTitle, design: .default, weight: .bold))
                .tracking(-1)
                .foregroundStyle(Theme.cream)
            Text(subtitle).font(.subheadline).foregroundStyle(Theme.creamSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
