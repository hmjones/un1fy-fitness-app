import Foundation

/// Reads the per-member `visits` table directly from Supabase via the REST API,
/// using the publishable (anon) key. Mirrors how the leaderboard service works.
nonisolated final class SupabaseVisitsService: Sendable {
    private let supabaseURL = "https://gzxphxqjjdickalcilrq.supabase.co"
    private let anonKey = "sb_publishable_XqcO2QArx3pkmGO6g05W0Q_v9cRhc6p"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches every visit for a single member, newest first.
    func fetchVisits(clientId: Int, limit: Int = 1000) async throws -> [Visit] {
        guard var components = URLComponents(string: "\(supabaseURL)/rest/v1/visits") else {
            throw SupabaseLeaderboardError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "client_id", value: "eq.\(clientId)"),
            URLQueryItem(name: "order", value: "visit_date.desc"),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url else {
            throw SupabaseLeaderboardError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw SupabaseLeaderboardError.invalidResponse(status: status)
        }

        return try JSONDecoder().decode([Visit].self, from: data)
    }
}
