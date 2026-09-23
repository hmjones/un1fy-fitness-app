import Foundation

/// Talks to the Supabase `feed_posts`, `feed_likes`, and `feed_comments`
/// tables (plus the `feed-photos` storage bucket) via the REST API, using the
/// publishable (anon) key. Mirrors how the visits/leaderboard services work.
nonisolated final class SupabaseFeedService: Sendable {
    private let supabaseURL = "https://gzxphxqjjdickalcilrq.supabase.co"
    private let anonKey = "sb_publishable_XqcO2QArx3pkmGO6g05W0Q_v9cRhc6p"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches the newest feed posts with their likes and comment counts
    /// embedded in a single query.
    func fetchPosts(limit: Int = 50) async throws -> [FeedPost] {
        var components = try restComponents(path: "feed_posts")
        components.queryItems = [
            URLQueryItem(name: "select", value: "*,feed_likes(client_id),feed_comments(count)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        let data = try await perform(request: try makeRequest(components: components, method: "GET"))
        return try JSONDecoder().decode([FeedPost].self, from: data)
    }

    /// Inserts auto-posts, silently skipping any whose `visit_key` already
    /// exists (so the same class is never posted twice, even across devices).
    /// Returns only the rows that were actually created.
    func createPosts(_ inserts: [FeedPostInsert]) async throws -> [FeedPost] {
        guard !inserts.isEmpty else { return [] }
        var components = try restComponents(path: "feed_posts")
        components.queryItems = [
            URLQueryItem(name: "on_conflict", value: "visit_key")
        ]
        var request = try makeRequest(components: components, method: "POST")
        request.setValue("resolution=ignore-duplicates,return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode(inserts)
        let data = try await perform(request: request)
        return (try? JSONDecoder().decode([FeedPost].self, from: data)) ?? []
    }

    /// Fills in Apple Health calories on a post that doesn't have them yet
    /// (server-created posts start without calories). The `is.null` filter
    /// ensures an existing value is never overwritten.
    func setCalories(postId: String, calories: Int) async throws {
        var components = try restComponents(path: "feed_posts")
        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(postId)"),
            URLQueryItem(name: "calories", value: "is.null")
        ]
        var request = try makeRequest(components: components, method: "PATCH")
        request.httpBody = try JSONEncoder().encode(["calories": calories])
        _ = try await perform(request: request)
    }

    /// Attaches an uploaded photo (and optional caption) to an existing post.
    func setPhoto(postId: String, photoUrl: String, caption: String?) async throws {
        var components = try restComponents(path: "feed_posts")
        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(postId)")
        ]
        var request = try makeRequest(components: components, method: "PATCH")
        var payload: [String: String] = ["photo_url": photoUrl]
        if let caption, !caption.trimmingCharacters(in: .whitespaces).isEmpty {
            payload["caption"] = caption
        }
        request.httpBody = try JSONEncoder().encode(payload)
        _ = try await perform(request: request)
    }

    /// Adds a thumbs-up. Duplicate likes are ignored server-side via the
    /// unique (post_id, client_id) constraint.
    func addLike(postId: String, clientId: Int, memberName: String) async throws {
        var components = try restComponents(path: "feed_likes")
        components.queryItems = [
            URLQueryItem(name: "on_conflict", value: "post_id,client_id")
        ]
        var request = try makeRequest(components: components, method: "POST")
        request.setValue("resolution=ignore-duplicates", forHTTPHeaderField: "Prefer")
        let payload: [String: AnyEncodableValue] = [
            "post_id": .string(postId),
            "client_id": .int(clientId),
            "member_name": .string(memberName)
        ]
        request.httpBody = try JSONEncoder().encode(payload)
        _ = try await perform(request: request)
    }

    /// Removes the member's thumbs-up from a post.
    func removeLike(postId: String, clientId: Int) async throws {
        var components = try restComponents(path: "feed_likes")
        components.queryItems = [
            URLQueryItem(name: "post_id", value: "eq.\(postId)"),
            URLQueryItem(name: "client_id", value: "eq.\(clientId)")
        ]
        let request = try makeRequest(components: components, method: "DELETE")
        _ = try await perform(request: request)
    }

    /// Fetches all comments for a post, oldest first.
    func fetchComments(postId: String) async throws -> [FeedComment] {
        var components = try restComponents(path: "feed_comments")
        components.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "post_id", value: "eq.\(postId)"),
            URLQueryItem(name: "order", value: "created_at.asc")
        ]
        let data = try await perform(request: try makeRequest(components: components, method: "GET"))
        return try JSONDecoder().decode([FeedComment].self, from: data)
    }

    /// Adds a comment and returns the created row.
    func addComment(_ insert: FeedCommentInsert) async throws -> FeedComment? {
        let components = try restComponents(path: "feed_comments")
        var request = try makeRequest(components: components, method: "POST")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode(insert)
        let data = try await perform(request: request)
        return (try? JSONDecoder().decode([FeedComment].self, from: data))?.first
    }

    /// Uploads a JPEG to the public `feed-photos` bucket and returns its
    /// public URL.
    func uploadPhoto(data: Data, postId: String) async throws -> String {
        let objectPath = "\(postId)-\(Int(Date().timeIntervalSince1970)).jpg"
        guard let url = URL(string: "\(supabaseURL)/storage/v1/object/feed-photos/\(objectPath)") else {
            throw SupabaseLeaderboardError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        request.httpBody = data
        _ = try await perform(request: request)
        return "\(supabaseURL)/storage/v1/object/public/feed-photos/\(objectPath)"
    }

    // MARK: - Helpers

    private func restComponents(path: String) throws -> URLComponents {
        guard let components = URLComponents(string: "\(supabaseURL)/rest/v1/\(path)") else {
            throw SupabaseLeaderboardError.invalidURL
        }
        return components
    }

    private func makeRequest(components: URLComponents, method: String) throws -> URLRequest {
        guard let url = components.url else {
            throw SupabaseLeaderboardError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if method != "GET" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func perform(request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw SupabaseLeaderboardError.invalidResponse(status: status)
        }
        return data
    }
}

/// Minimal heterogeneous JSON value for small ad-hoc payloads.
nonisolated enum AnyEncodableValue: Encodable, Sendable {
    case string(String)
    case int(Int)

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        }
    }
}
