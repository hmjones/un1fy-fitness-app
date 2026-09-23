import Foundation

nonisolated enum BadgeCategory: String, Codable, CaseIterable, Sendable {
    case milestone = "Milestones"
    case streak = "Streaks"
    case variety = "Variety"
    case timeBased = "Time-Based"
}

nonisolated struct Badge: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: BadgeCategory
    let requirement: String
    var isUnlocked: Bool
    var dateEarned: Date?

    static let allBadges: [Badge] = [
        Badge(id: "first_class", name: "First Class", description: "Completed your very first class at UN1FY.", icon: "star.fill", category: .milestone, requirement: "Complete 1 class", isUnlocked: false),
        Badge(id: "ten_classes", name: "10 Classes", description: "You've shown up 10 times. That's dedication.", icon: "flame.fill", category: .milestone, requirement: "Complete 10 classes", isUnlocked: false),
        Badge(id: "twenty_five_classes", name: "25 Classes", description: "Quarter century! You're building something real.", icon: "bolt.fill", category: .milestone, requirement: "Complete 25 classes", isUnlocked: false),
        Badge(id: "fifty_classes", name: "50 Classes", description: "Half a hundred. You're unstoppable.", icon: "trophy.fill", category: .milestone, requirement: "Complete 50 classes", isUnlocked: false),
        Badge(id: "hundred_classes", name: "100 Classes", description: "Triple digits. Legend status.", icon: "crown.fill", category: .milestone, requirement: "Complete 100 classes", isUnlocked: false),
        Badge(id: "two_fifty_classes", name: "250 Classes", description: "Two hundred fifty. You ARE UN1FY.", icon: "sparkles", category: .milestone, requirement: "Complete 250 classes", isUnlocked: false),

        Badge(id: "streak_7", name: "7-Day Streak", description: "A full week without missing a beat.", icon: "7.circle.fill", category: .streak, requirement: "7 consecutive days", isUnlocked: false),
        Badge(id: "streak_14", name: "14-Day Streak", description: "Two weeks strong. Nothing can stop you.", icon: "14.circle.fill", category: .streak, requirement: "14 consecutive days", isUnlocked: false),
        Badge(id: "streak_30", name: "30-Day Streak", description: "A full month. Habits are forged.", icon: "30.circle.fill", category: .streak, requirement: "30 consecutive days", isUnlocked: false),
        Badge(id: "streak_60", name: "60-Day Streak", description: "Two months of pure commitment.", icon: "60.circle.fill", category: .streak, requirement: "60 consecutive days", isUnlocked: false),
        Badge(id: "streak_90", name: "90-Day Streak", description: "90 days. This is who you are now.", icon: "90.circle.fill", category: .streak, requirement: "90 consecutive days", isUnlocked: false),

        Badge(id: "balanced", name: "Balanced", description: "Power35 and Sculpt45 in one week. Balance is key.", icon: "scalemass.fill", category: .variety, requirement: "Both Power35 + Sculpt45 in one week", isUnlocked: false),
        Badge(id: "triple_threat", name: "Triple Threat", description: "All three class types in one week. Versatile.", icon: "triangle.fill", category: .variety, requirement: "All 3 class types in one week", isUnlocked: false),

        Badge(id: "early_bird", name: "Early Bird", description: "Up before the sun. 5 AM warrior.", icon: "sunrise.fill", category: .timeBased, requirement: "Attend a 5 AM class", isUnlocked: false),
        Badge(id: "night_owl", name: "Night Owl", description: "Evening energy. 7 PM and later.", icon: "moon.stars.fill", category: .timeBased, requirement: "Attend a 7 PM+ class", isUnlocked: false),
        Badge(id: "weekend_warrior", name: "Weekend Warrior", description: "Four weekend classes in one month. No rest days.", icon: "calendar.badge.checkmark", category: .timeBased, requirement: "4 weekend classes in a month", isUnlocked: false),
    ]
}
