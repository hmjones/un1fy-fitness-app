import Foundation

nonisolated struct Challenge: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let targetCount: Int
    var currentCount: Int
    let startDate: Date
    let endDate: Date
    var isActive: Bool
    var leaderboard: [LeaderboardEntry]
    var winner: String?
}

nonisolated struct LeaderboardEntry: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let score: Int
    let avatarInitials: String
}
