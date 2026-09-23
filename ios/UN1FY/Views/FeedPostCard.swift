import SwiftUI

/// A single community feed post: avatar, headline, optional photo, caption,
/// and the thumbs-up / comment action row.
struct FeedPostCard: View {
    let post: FeedPost
    let currentClientId: Int?
    let canInteract: Bool
    let onLike: () -> Void
    let onOpenComments: () -> Void
    /// Present the share-to-socials sheet; only provided for the member's own posts.
    var onShare: (() -> Void)? = nil

    private var isLiked: Bool {
        post.isLiked(by: currentClientId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            headline

            if let photoUrl = post.photoUrl, let url = URL(string: photoUrl) {
                photo(url: url)
            }

            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(Theme.creamSecondary)
            }

            actionRow
        }
        .padding(16)
        .softCard()
    }

    private var header: some View {
        HStack(spacing: 12) {
            AvatarView(
                clientId: post.clientId,
                initials: post.initials,
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(post.memberName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.cream)
                if let created = post.createdDate {
                    Text(created.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(Theme.creamTertiary)
                }
            }

            Spacer()

            Image(systemName: post.classType.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.creamSecondary)
                .frame(width: 36, height: 36)
                .background(Theme.neutralFill)
                .clipShape(.rect(cornerRadius: 11))
        }
    }

    private var headline: some View {
        (
            Text(post.memberName)
                .fontWeight(.bold)
            + Text(" \(post.actionText)")
        )
        .font(.subheadline)
        .foregroundStyle(Theme.cream)
        .lineSpacing(3)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func photo(url: URL) -> some View {
        Theme.neutralFill
            .frame(height: 220)
            .overlay {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(Theme.creamTertiary)
                    default:
                        ProgressView()
                            .tint(Theme.creamTertiary)
                    }
                }
            }
            .clipShape(.rect(cornerRadius: 14, style: .continuous))
    }

    private var actionRow: some View {
        HStack(spacing: 20) {
            Button(action: onLike) {
                HStack(spacing: 6) {
                    Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isLiked ? Theme.accent : Theme.creamSecondary)
                        .symbolEffect(.bounce, value: isLiked)
                    if post.likeCount > 0 {
                        Text("\(post.likeCount)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isLiked ? Theme.accent : Theme.creamSecondary)
                            .contentTransition(.numericText())
                    }
                }
                .frame(minWidth: 44, minHeight: 32, alignment: .leading)
            }
            .disabled(!canInteract)

            Button(action: onOpenComments) {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.right")
                        .font(.body.weight(.semibold))
                    if post.commentCount > 0 {
                        Text("\(post.commentCount)")
                            .font(.subheadline.weight(.semibold))
                            .contentTransition(.numericText())
                    }
                }
                .foregroundStyle(Theme.creamSecondary)
                .frame(minWidth: 44, minHeight: 32, alignment: .leading)
            }

            Spacer()

            if let onShare {
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.creamSecondary)
                        .frame(minWidth: 44, minHeight: 32, alignment: .trailing)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: post.likeCount)
    }
}
