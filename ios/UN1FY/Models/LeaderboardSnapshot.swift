import Foundation

/// A period (board) shown on the leaderboard. Maps to the `period` column in
/// the Supabase `leaderboard_snapshot` table.
nonisolated enum LeaderboardPeriod: String, CaseIterable, Identifiable, Sendable {
    case month
    case allTime = "all_time"
    case streak
    case milestone

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month: return "This Month"
        case .allTime: return "All Time"
        case .streak: return "Streaks"
        case .milestone: return "Milestones"
        }
    }

    var icon: String {
        switch self {
        case .month: return "calendar"
        case .allTime: return "crown.fill"
        case .streak: return "flame.fill"
        case .milestone: return "flag.checkered"
        }
    }

    /// Unit label for a row's `value` (e.g. "classes", "days").
    var unit: String {
        switch self {
        case .month, .allTime: return "classes"
        case .streak: return "days"
        case .milestone: return "classes"
        }
    }
}

/// A single row of the leaderboard, matching the Supabase `leaderboard_snapshot`
/// schema. `metadata` varies by period and is decoded loosely.
nonisolated struct LeaderboardRow: Identifiable, Codable, Sendable {
    let id: String
    let generatedAt: Date?
    let period: String
    let clientId: Int
    let displayName: String
    let rank: Int
    let value: Int
    let metadata: LeaderboardMetadata?

    enum CodingKeys: String, CodingKey {
        case id
        case generatedAt = "generated_at"
        case period
        case clientId = "client_id"
        case displayName = "display_name"
        case rank
        case value
        case metadata
    }

    /// Two-letter initials derived from the display name (e.g. "Maycee B." → "MB").
    var avatarInitials: String {
        let parts = displayName
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
        let initials = String(parts).uppercased()
        return initials.isEmpty ? "?" : initials
    }
}

/// Loosely-typed metadata payload from the `metadata` jsonb column.
/// - streaks: `{ streak_start }`
/// - milestones: `{ crossed_date, window }`
nonisolated struct LeaderboardMetadata: Codable, Sendable {
    let streakStart: String?
    let crossedDate: String?
    let window: String?

    enum CodingKeys: String, CodingKey {
        case streakStart = "streak_start"
        case crossedDate = "crossed_date"
        case window
    }
}
