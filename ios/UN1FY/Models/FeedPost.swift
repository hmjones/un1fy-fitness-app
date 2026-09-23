import Foundation

/// A single post in the community feed, stored in the Supabase `feed_posts`
/// table. Embedded `feed_likes` rows and the `feed_comments` count come back
/// from PostgREST resource embedding in the same query.
nonisolated struct FeedPost: Identifiable, Decodable, Sendable {
    let id: String
    let clientId: Int
    let memberName: String
    let className: String?
    let classTypeRaw: String?
    let classDatetime: String?
    let visitKey: String
    var calories: Int?
    var photoUrl: String?
    var caption: String?
    let createdAt: String
    var likeClientIds: [Int]
    var commentCount: Int

    private enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case memberName = "member_name"
        case className = "class_name"
        case classTypeRaw = "class_type"
        case classDatetime = "class_datetime"
        case visitKey = "visit_key"
        case calories
        case photoUrl = "photo_url"
        case caption
        case createdAt = "created_at"
        case feedLikes = "feed_likes"
        case feedComments = "feed_comments"
    }

    private nonisolated struct LikeRef: Decodable, Sendable {
        let clientId: Int

        enum CodingKeys: String, CodingKey {
            case clientId = "client_id"
        }
    }

    private nonisolated struct CountRef: Decodable, Sendable {
        let count: Int
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        clientId = try container.decode(Int.self, forKey: .clientId)
        memberName = try container.decode(String.self, forKey: .memberName)
        className = try container.decodeIfPresent(String.self, forKey: .className)
        classTypeRaw = try container.decodeIfPresent(String.self, forKey: .classTypeRaw)
        classDatetime = try container.decodeIfPresent(String.self, forKey: .classDatetime)
        visitKey = try container.decode(String.self, forKey: .visitKey)
        calories = try container.decodeIfPresent(Int.self, forKey: .calories)
        photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        likeClientIds = ((try? container.decodeIfPresent([LikeRef].self, forKey: .feedLikes)) ?? nil)?
            .map(\.clientId) ?? []
        commentCount = ((try? container.decodeIfPresent([CountRef].self, forKey: .feedComments)) ?? nil)?
            .first?.count ?? 0
    }

    var likeCount: Int { likeClientIds.count }

    func isLiked(by clientId: Int?) -> Bool {
        guard let clientId else { return false }
        return likeClientIds.contains(clientId)
    }

    /// Maps the stored class type / name to one of the app's `ClassType`s.
    var classType: ClassType {
        if let classTypeRaw, let mapped = ClassType(rawValue: classTypeRaw) {
            return mapped
        }
        guard let name = className?.lowercased() else { return .other }
        if name.contains("power") { return .power35 }
        if name.contains("sculpt") { return .sculpt45 }
        if name.contains("run") { return .runClub }
        return .other
    }

    /// The best display name for the class in the post headline.
    var displayClassName: String {
        if let className, !className.trimmingCharacters(in: .whitespaces).isEmpty {
            return className
        }
        if classType != .other {
            return classType.rawValue
        }
        return "a class"
    }

    /// The class start parsed from `class_datetime`. Note: Mindbody stores the
    /// studio's wall-clock class time tagged as UTC.
    var classDate: Date? {
        guard let classDatetime else { return nil }
        return FeedPost.isoFormatter.date(from: classDatetime)
            ?? FeedPost.isoFormatterNoFraction.date(from: classDatetime)
    }

    /// Friendly class time (e.g. "5:30 PM"), formatted in UTC to preserve the
    /// studio's wall-clock time.
    var classTimeString: String {
        guard let classDate else { return "" }
        return FeedPost.displayTimeFormatter.string(from: classDate)
    }

    /// The real timestamp the post was created, used for relative time labels.
    var createdDate: Date? {
        FeedPost.isoFormatter.date(from: createdAt)
            ?? FeedPost.isoFormatterNoFraction.date(from: createdAt)
    }

    /// Headline body following the member's name, e.g.
    /// "burned 500 calories in Power 35 at 5:30 PM".
    var actionText: String {
        var text: String
        if let calories, calories > 0 {
            text = "burned \(calories) calories in \(displayClassName)"
        } else {
            text = "completed \(displayClassName)"
        }
        let time = classTimeString
        if !time.isEmpty {
            text += " at \(time)"
        }
        return text
    }

    /// Avatar initials derived from the member's display name (e.g. "JR").
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

    private static let displayTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}

/// Payload for inserting a new auto-post into `feed_posts`.
nonisolated struct FeedPostInsert: Encodable, Sendable {
    let clientId: Int
    let memberName: String
    let className: String?
    let classType: String
    let classDatetime: String?
    let visitKey: String
    let calories: Int?

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case memberName = "member_name"
        case className = "class_name"
        case classType = "class_type"
        case classDatetime = "class_datetime"
        case visitKey = "visit_key"
        case calories
    }
}
