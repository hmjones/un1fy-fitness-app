import SwiftUI

/// Drives the Home tab's community feed: loading posts, auto-posting newly
/// completed classes (with Apple Health calories), the "add a photo" prompt,
/// thumbs-ups, and comments.
@Observable
@MainActor
final class FeedStore {
    var posts: [FeedPost] = []
    var isLoading: Bool = false
    var photoPromptPost: FeedPost?
    var isUploadingPhoto: Bool = false

    private let service = SupabaseFeedService()
    private let health = HealthKitService()
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    private(set) var clientId: Int?
    private(set) var memberName: String = ""

    private static let dismissedPromptsKey = "dismissedPhotoPromptIds"

    /// The member identity used for posting/liking/commenting — same
    /// Mindbody-derived display name the leaderboard uses.
    func configure(clientId: Int?, memberName: String) {
        self.clientId = clientId
        self.memberName = memberName
    }

    var canInteract: Bool {
        clientId != nil && !memberName.isEmpty
    }

    /// Whether a feed post belongs to the current member. Matches by client id
    /// first, then falls back to the display name — studio databases can hold
    /// duplicate client ids for the same member (e.g. server-created posts
    /// keyed by a second id), and a strict id match made those posts invisible
    /// on the You tab, skipped the photo prompt, and blocked calorie
    /// enrichment.
    func isOwnPost(_ post: FeedPost) -> Bool {
        if let clientId, post.clientId == clientId {
            return true
        }
        guard !memberName.isEmpty else { return false }
        return post.memberName.compare(memberName, options: [.caseInsensitive]) == .orderedSame
    }

    /// Reloads the shared feed (posts + likes + comment counts).
    func refresh() async {
        isLoading = posts.isEmpty
        do {
            posts = try await service.fetchPosts()
            updatePhotoPrompt()
        } catch {
            print("[UN1FY] Feed fetch failed: \(error)")
        }
        isLoading = false
    }

    /// Detects classes the member completed in the last 48 hours that aren't
    /// in the feed yet, pulls their Apple Health calories, and auto-posts
    /// them. The `visit_key` unique constraint guarantees each class posts
    /// exactly once, even across devices — a server job also publishes every
    /// attendee's classes on a schedule, so this is the "instant" path, plus
    /// the only path that can attach Apple Health calories.
    func syncCompletedClasses(from visits: [Visit]) async {
        guard let clientId, !memberName.isEmpty else {
            await refresh()
            return
        }

        // Mindbody stores wall-clock class times tagged as UTC, so compare
        // against "now" expressed in the same tagged-UTC frame.
        let offset = TimeInterval(TimeZone.current.secondsFromGMT())
        let nowTagged = Date().addingTimeInterval(offset)
        let cutoff = nowTagged.addingTimeInterval(-48 * 3600)

        // A class counts as completed once its start time has passed — the
        // `signed_in` flag lags behind in the visits table, so don't gate on it
        // (same rule the attendance stats use).
        var seenKeys = Set<String>()
        let candidates = visits
            .filter { visit in
                guard let date = visit.date else { return false }
                return date >= cutoff && date <= nowTagged
            }
            .filter { seenKeys.insert(visitKey(for: $0, clientId: clientId)).inserted }

        guard !candidates.isEmpty else {
            await refresh()
            await enrichOwnPostsWithCalories()
            return
        }

        let healthReady = await health.requestReadAccess()

        var inserts: [FeedPostInsert] = []
        for visit in candidates {
            var calories: Int?
            if healthReady, let taggedStart = visit.date {
                // Convert the tagged-UTC wall-clock time back to the real
                // instant so it lines up with Apple Health sample timestamps.
                let realStart = taggedStart.addingTimeInterval(-offset)
                let window = classDuration(forClassName: visit.className)
                calories = await health.activeCalories(
                    start: realStart.addingTimeInterval(-5 * 60),
                    end: realStart.addingTimeInterval(window + 10 * 60)
                )
            }
            inserts.append(
                FeedPostInsert(
                    clientId: clientId,
                    memberName: memberName,
                    className: visit.className,
                    classType: visit.classType.rawValue,
                    classDatetime: visit.visitDatetime,
                    visitKey: visitKey(for: visit, clientId: clientId),
                    calories: calories
                )
            )
        }

        do {
            _ = try await service.createPosts(inserts)
        } catch {
            print("[UN1FY] Feed auto-post failed: \(error)")
        }

        await refresh()
        await enrichOwnPostsWithCalories()
    }

    /// Fills in Apple Health calories on the member's own recent posts that
    /// don't have them yet — these are typically posts the server job created
    /// while the app was closed. The service only writes when the post's
    /// calories are still null, so nothing is ever overwritten.
    private func enrichOwnPostsWithCalories() async {
        guard clientId != nil else { return }

        let offset = TimeInterval(TimeZone.current.secondsFromGMT())
        let nowTagged = Date().addingTimeInterval(offset)
        let cutoff = nowTagged.addingTimeInterval(-48 * 3600)

        let candidates = posts.filter { post in
            guard isOwnPost(post), post.calories == nil else { return false }
            guard let taggedStart = post.classDate else { return false }
            return taggedStart >= cutoff && taggedStart <= nowTagged
        }
        guard !candidates.isEmpty else { return }
        guard await health.requestReadAccess() else { return }

        for post in candidates {
            guard let taggedStart = post.classDate else { continue }
            let realStart = taggedStart.addingTimeInterval(-offset)
            let window = classDuration(forClassName: post.className)
            guard let calories = await health.activeCalories(
                start: realStart.addingTimeInterval(-5 * 60),
                end: realStart.addingTimeInterval(window + 10 * 60)
            ), calories > 0 else { continue }

            do {
                try await service.setCalories(postId: post.id, calories: calories)
                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[index].calories = calories
                }
            } catch {
                print("[UN1FY] Calorie enrichment failed: \(error)")
            }
        }
    }

    /// Adds/removes the member's thumbs-up with an optimistic UI update.
    func toggleLike(post: FeedPost) async {
        guard let clientId else { return }
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        haptic.impactOccurred()
        let wasLiked = posts[index].likeClientIds.contains(clientId)
        if wasLiked {
            posts[index].likeClientIds.removeAll { $0 == clientId }
        } else {
            posts[index].likeClientIds.append(clientId)
        }

        do {
            if wasLiked {
                try await service.removeLike(postId: post.id, clientId: clientId)
            } else {
                try await service.addLike(postId: post.id, clientId: clientId, memberName: memberName)
            }
        } catch {
            print("[UN1FY] Like toggle failed: \(error)")
            // Roll back the optimistic change.
            if let rollbackIndex = posts.firstIndex(where: { $0.id == post.id }) {
                if wasLiked {
                    posts[rollbackIndex].likeClientIds.append(clientId)
                } else {
                    posts[rollbackIndex].likeClientIds.removeAll { $0 == clientId }
                }
            }
        }
    }

    /// Loads all comments for a post.
    func comments(for post: FeedPost) async -> [FeedComment] {
        do {
            return try await service.fetchComments(postId: post.id)
        } catch {
            print("[UN1FY] Comments fetch failed: \(error)")
            return []
        }
    }

    /// Posts a comment and bumps the post's comment count locally.
    func addComment(to post: FeedPost, body: String) async -> FeedComment? {
        guard let clientId, !memberName.isEmpty else { return nil }
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        do {
            let comment = try await service.addComment(
                FeedCommentInsert(postId: post.id, clientId: clientId, memberName: memberName, body: trimmed)
            )
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index].commentCount += 1
            }
            return comment
        } catch {
            print("[UN1FY] Comment failed: \(error)")
            return nil
        }
    }

    /// Uploads the picked photo, attaches it (plus optional caption) to the
    /// prompted post, and clears the prompt.
    func attachPhoto(imageData: Data, caption: String) async {
        guard let post = photoPromptPost else { return }
        guard let prepared = preparedJPEG(from: imageData) else { return }

        isUploadingPhoto = true
        do {
            let url = try await service.uploadPhoto(data: prepared, postId: post.id)
            try await service.setPhoto(postId: post.id, photoUrl: url, caption: caption)
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index].photoUrl = url
                let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
                posts[index].caption = trimmedCaption.isEmpty ? nil : trimmedCaption
            }
            markPromptHandled(postId: post.id)
        } catch {
            print("[UN1FY] Photo upload failed: \(error)")
        }
        isUploadingPhoto = false
    }

    /// Hides the photo prompt for this post permanently.
    func dismissPhotoPrompt() {
        guard let post = photoPromptPost else { return }
        markPromptHandled(postId: post.id)
    }

    // MARK: - Private

    /// Surfaces the newest own post from the last 24 hours that has no photo
    /// and hasn't been dismissed, as the "add a photo?" prompt.
    private func updatePhotoPrompt() {
        guard clientId != nil else {
            photoPromptPost = nil
            return
        }
        let dismissed = dismissedPromptIds
        let candidate = posts
            .filter { isOwnPost($0) && $0.photoUrl == nil && !dismissed.contains($0.id) }
            .filter { post in
                guard let created = post.createdDate else { return false }
                return Date().timeIntervalSince(created) < 24 * 3600
            }
            .max { ($0.createdDate ?? .distantPast) < ($1.createdDate ?? .distantPast) }
        photoPromptPost = candidate
    }

    private func markPromptHandled(postId: String) {
        var dismissed = dismissedPromptIds
        dismissed.insert(postId)
        UserDefaults.standard.set(Array(dismissed), forKey: FeedStore.dismissedPromptsKey)
        photoPromptPost = nil
        updatePhotoPrompt()
    }

    private var dismissedPromptIds: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: FeedStore.dismissedPromptsKey) ?? [])
    }

    /// Stable per-class-occurrence key, matching the dedupe key the stats use.
    private func visitKey(for visit: Visit, clientId: Int) -> String {
        "\(clientId)-\(visit.classId ?? visit.id)-\(visit.visitDate)"
    }

    /// Approximate class length used as the Apple Health query window.
    private func classDuration(forClassName className: String?) -> TimeInterval {
        let name = className?.lowercased() ?? ""
        if name.contains("power") { return 35 * 60 }
        if name.contains("sculpt") { return 45 * 60 }
        return 60 * 60
    }

    /// Downscales and re-encodes the picked image so uploads stay small.
    private func preparedJPEG(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxDimension: CGFloat = 1280
        let largestSide = max(image.size.width, image.size.height)
        guard largestSide > maxDimension else {
            return image.jpegData(compressionQuality: 0.8)
        }
        let scale = maxDimension / largestSide
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}
