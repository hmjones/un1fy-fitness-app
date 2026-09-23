import SwiftUI

/// Bottom sheet showing a post's comments with a compose bar pinned at the bottom.
struct FeedCommentsSheet: View {
    let feed: FeedStore
    let post: FeedPost

    @State private var comments: [FeedComment] = []
    @State private var isLoading: Bool = true
    @State private var draft: String = ""
    @State private var isSending: Bool = false
    @FocusState private var isComposerFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                commentsList
                composerBar
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.cream)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
        .task {
            comments = await feed.comments(for: post)
            isLoading = false
        }
    }

    private var commentsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                if isLoading {
                    ProgressView()
                        .tint(Theme.creamTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if comments.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.title2)
                            .foregroundStyle(Theme.creamTertiary)
                        Text("No comments yet")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.creamSecondary)
                        Text("Be the first to cheer them on.")
                            .font(.caption)
                            .foregroundStyle(Theme.creamTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    ForEach(comments) { comment in
                        commentRow(comment)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func commentRow(_ comment: FeedComment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(
                clientId: comment.clientId,
                initials: comment.initials,
                size: 32
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(comment.memberName)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Theme.cream)
                    if let created = comment.createdDate {
                        Text(created.formatted(.relative(presentation: .named)))
                            .font(.caption2)
                            .foregroundStyle(Theme.creamTertiary)
                    }
                }
                Text(comment.body)
                    .font(.subheadline)
                    .foregroundStyle(Theme.creamSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var composerBar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Theme.subtleDivider)

            HStack(spacing: 12) {
                TextField(
                    feed.canInteract ? "Add a comment…" : "Connect Mindbody to comment",
                    text: $draft,
                    axis: .vertical
                )
                .font(.subheadline)
                .foregroundStyle(Theme.cream)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Theme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                )
                .focused($isComposerFocused)
                .disabled(!feed.canInteract || isSending)

                Button {
                    Task { await send() }
                } label: {
                    if isSending {
                        ProgressView()
                            .tint(Theme.creamTertiary)
                            .frame(width: 44, height: 44)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(canSend ? Theme.accent : Theme.creamTertiary)
                            .frame(width: 44, height: 44)
                    }
                }
                .disabled(!canSend || isSending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Theme.background)
    }

    private var canSend: Bool {
        feed.canInteract && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() async {
        guard canSend else { return }
        isSending = true
        if let comment = await feed.addComment(to: post, body: draft) {
            comments.append(comment)
            draft = ""
        }
        isSending = false
    }
}
