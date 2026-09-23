import Foundation

/// Talks to the Supabase `member_profiles` table (plus the public
/// `profile-photos` storage bucket) via the REST API, using the publishable
/// (anon) key. Mirrors how the feed/visits services work.
nonisolated final class SupabaseProfileService: Sendable {
    private let supabaseURL = "https://gzxphxqjjdickalcilrq.supabase.co"
    private let anonKey = "sb_publishable_XqcO2QArx3pkmGO6g05W0Q_v9cRhc6p"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches every member profile that has a photo set, so avatars can be
    /// resolved for the whole community in one query.
    func fetchProfiles() async throws -> [MemberProfileRecord] {
        var components = try restComponents(path: "member_profiles")
        components.queryItems = [
            URLQueryItem(name: "select", value: "client_id,member_name,photo_url"),
            URLQueryItem(name: "photo_url", value: "not.is.null")
        ]
        let data = try await perform(request: try makeRequest(components: components, method: "GET"))
        return try JSONDecoder().decode([MemberProfileRecord].self, from: data)
    }

    /// Creates or updates the member's profile row with the new photo URL.
    func upsertProfile(clientId: Int, memberName: String, photoUrl: String) async throws {
        var components = try restComponents(path: "member_profiles")
        components.queryItems = [
            URLQueryItem(name: "on_conflict", value: "client_id")
        ]
        var request = try makeRequest(components: components, method: "POST")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode(
            MemberProfileUpsert(clientId: clientId, memberName: memberName, photoUrl: photoUrl)
        )
        _ = try await perform(request: request)
    }

    /// Clears the member's photo so their initials show again.
    func clearPhoto(clientId: Int) async throws {
        var components = try restComponents(path: "member_profiles")
        components.queryItems = [
            URLQueryItem(name: "client_id", value: "eq.\(clientId)")
        ]
        var request = try makeRequest(components: components, method: "PATCH")
        request.httpBody = Data(#"{"photo_url":null}"#.utf8)
        _ = try await perform(request: request)
    }

    /// Uploads a JPEG to the public `profile-photos` bucket and returns its
    /// public URL. The filename is timestamped so image caches never serve a
    /// stale photo after a change.
    func uploadPhoto(data: Data, clientId: Int) async throws -> String {
        let objectPath = "\(clientId)-\(Int(Date().timeIntervalSince1970)).jpg"
        guard let url = URL(string: "\(supabaseURL)/storage/v1/object/profile-photos/\(objectPath)") else {
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
        return "\(supabaseURL)/storage/v1/object/public/profile-photos/\(objectPath)"
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

/// Payload for upserting a row into `member_profiles`.
nonisolated struct MemberProfileUpsert: Encodable, Sendable {
    let clientId: Int
    let memberName: String
    let photoUrl: String

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case memberName = "member_name"
        case photoUrl = "photo_url"
    }
}
