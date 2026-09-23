import Foundation

nonisolated enum MotivationalQuotes {
    static let quotes: [String] = [
        "The only bad workout is the one that didn't happen.",
        "You don't have to be great to start, but you have to start to be great.",
        "Your body can stand almost anything. It's your mind that you have to convince.",
        "Strength doesn't come from what you can do. It comes from overcoming what you thought you couldn't.",
        "The pain you feel today will be the strength you feel tomorrow.",
        "Don't limit your challenges. Challenge your limits.",
        "One hour is 4% of your day. No excuses.",
        "Be stronger than your strongest excuse.",
        "The difference between try and triumph is just a little umph.",
        "Sweat is just fat crying.",
        "Wake up. Work out. Look hot. Kick ass.",
        "Today's actions are tomorrow's results.",
        "You're only one workout away from a good mood.",
        "Push harder than yesterday if you want a different tomorrow.",
        "Fall in love with taking care of yourself.",
        "Your health is an investment, not an expense.",
        "Small daily improvements are the key to staggering long-term results.",
        "The body achieves what the mind believes.",
        "Make yourself proud.",
        "Champions train. Losers complain.",
        "It never gets easier. You just get stronger.",
        "Success is what comes after you stop making excuses.",
        "A one-hour workout is 4% of your day. No excuses.",
        "Discipline is choosing between what you want now and what you want most.",
        "Every rep counts. Every class counts. You count.",
        "Fitness is not about being better than someone else. It's about being better than you used to be.",
        "Show up. Work hard. And trust the process.",
        "The hardest lift is lifting yourself off the couch.",
        "Earn your shower.",
        "You're not tired. You're uninspired. Get to class.",
        "Consistency is what transforms average into excellence.",
    ]

    static func quoteForToday() -> String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return quotes[dayOfYear % quotes.count]
    }
}
