import Foundation

nonisolated struct MemberProfile: Codable, Sendable {
    var firstName: String
    var lastName: String
    var memberSince: Date
    var totalClasses: Int
    var currentStreak: Int
    var longestStreak: Int
    var classesThisWeek: Int
    var classesThisMonth: Int
    var classesLastMonth: Int
    var mostClassesInMonth: Int
    var monthlyGoal: Int
    var pinnedBadgeIds: [String]
    var hideFromLeaderboard: Bool
    var hideCheckIns: Bool
    var streakReminders: Bool
    var milestoneNotifications: Bool
    var challengeUpdates: Bool
    var classReminders: Bool

    var fullName: String { "\(firstName) \(lastName)" }
}
