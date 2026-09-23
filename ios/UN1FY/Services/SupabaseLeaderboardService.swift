import Foundation

nonisolated enum SupabaseLeaderboardError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse(status: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The leaderboard request URL was invalid."
        case .invalidResponse(let status):
            return "The leaderboard server returned an error (\(status))."
        }
    }
}

/// Reads the `leaderboard_snapshot` table directly from Supabase via the REST API,
/// using the publishable (anon) key. This mirrors what the TV display does.
nonisolated final class SupabaseLeaderboardService: Sendable {
    private let supabaseURL = "https://gzxphxqjjdickalcilrq.supabase.co"
    private let anonKey = "sb_publishable_XqcO2QArx3pkmGO6g05W0Q_v9cRhc6p"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches all rows for a given period, ordered by rank ascending.
    func fetchBoard(period: LeaderboardPeriod, limit: Int = 25) async throws -> [LeaderboardRow] {
        guard var components = URLComponents(string: "\(supabaseURL)/rest/v1/leaderboard_snapshot") else {
            throw SupabaseLeaderboardError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "period", value: "eq.\(period.rawValue)"),
            URLQueryItem(name: "order", value: "rank.asc"),
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

        return try Self.makeDecoder().decode([LeaderboardRow].self, from: data)
    }

    /// Fetches every snapshot row for a single member, across all periods, by
    /// matching either their Mindbody `client_id` (preferred) or their display
    /// name (e.g. "Julie R."). Used to populate the member's own Home/Stats
    /// numbers from the same data that powers the leaderboard.
    func fetchMemberRows(displayName: String, clientId: Int?) async throws -> [LeaderboardRow] {
        guard var components = URLComponents(string: "\(supabaseURL)/rest/v1/leaderboard_snapshot") else {
            throw SupabaseLeaderboardError.invalidURL
        }

        var items: [URLQueryItem] = [URLQueryItem(name: "select", value: "*")]
        if let clientId {
            items.append(URLQueryItem(name: "client_id", value: "eq.\(clientId)"))
        } else {
            let trimmed = displayName.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return [] }
            items.append(URLQueryItem(name: "display_name", value: "eq.\(trimmed)"))
        }
        components.queryItems = items

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

        return try Self.makeDecoder().decode([LeaderboardRow].self, from: data)
    }

    /// Supabase timestamps carry fractional seconds (e.g.
    /// "2026-07-13T05:15:01.641+00:00"), which the strict `.iso8601` strategy
    /// cannot parse — that silently broke every snapshot fetch (and with it the
    /// member's client-id resolution and visit-derived stats). Use the tolerant
    /// project-wide date decoder instead.
    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = FlexibleDateDecoder.decodingStrategy()
        return decoder
    }
}
