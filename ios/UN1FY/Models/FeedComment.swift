import Foundation

/// A comment on a community feed post, stored in the Supabase `feed_comments` table.
nonisolated struct FeedComment: Identifiable, Codable, Sendable {
    let id: String
    let postId: String
    let clientId: Int
    let memberName: String
    let body: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case clientId = "client_id"
        case memberName = "member_name"
        case body
        case createdAt = "created_at"
    }

    /// The real timestamp the comment was created.
    var createdDate: Date? {
        FeedComment.isoFormatter.date(from: createdAt)
            ?? FeedComment.isoFormatterNoFraction.date(from: createdAt)
    }

    /// Avatar initials derived from the member's display name.
    var initials: String {
        let parts = memberName
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        let letters = parts.prefix(2).compactMap { $0.first }
        guard !letters.isEmpty else { return "?" }
        return String(letters).uppercased()
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

/// Payload for inserting a new comment into `feed_comments`.
nonisolated struct FeedCommentInsert: Encodable, Sendable {
    let postId: String
    let clientId: Int
    let memberName: String
    let body: String

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case clientId = "client_id"
        case memberName = "member_name"
        case body
    }
}
