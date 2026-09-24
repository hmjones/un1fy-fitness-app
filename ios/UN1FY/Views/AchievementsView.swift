import SwiftUI

struct AchievementsView: View {
    let store: MemberStore
    @State private var selectedBadge: Badge?
    @State private var appeared: Bool = false
    @State private var showCelebration: Bool = false
    @State private var celebrationTrigger: Int = 0

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection
                badgeCountSummary

                ForEach(BadgeCategory.allCases, id: \.self) { category in
                    badgeCategorySection(category)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Theme.background.ignoresSafeArea())
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailSheet(badge: badge)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.cardBackground)
        }
        .overlay {
            if showCelebration {
                CelebrationOverlay()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .sensoryFeedback(.success, trigger: celebrationTrigger)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
            checkForNewBadge()
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Achievements")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(Theme.cream)
            Spacer()
        }
        .opacity(appeared ? 1 : 0)
    }

    private var badgeCountSummary: some View {
        let earned = store.badges.filter { $0.isUnlocked }.count
        let total = store.badges.count
        return HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.subheadline)
                .foregroundStyle(Theme.cream)
                .frame(width: 38, height: 38)
                .background(Theme.neutralFill)
                .clipShape(.rect(cornerRadius: 12))
            Text("\(earned) of \(total) earned")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.cream)
            Spacer()
        }
        .padding(14)
        .softCard(cornerRadius: 18)
        .opacity(appeared ? 1 : 0)
    }

    private func badgeCategorySection(_ category: BadgeCategory) -> some View {
        let categoryBadges = store.badges.filter { $0.category == category }
        return VStack(alignment: .leading, spacing: 16) {
            Text(category.rawValue)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.cream)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(categoryBadges) { badge in
                    BadgeCell(badge: badge)
                        .onTapGesture {
                            selectedBadge = badge
                        }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private func checkForNewBadge() {
        if let badge = store.newlyUnlockedBadge {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                selectedBadge = badge
                withAnimation(.spring) {
                    showCelebration = true
                }
                celebrationTrigger += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showCelebration = false }
                    store.newlyUnlockedBadge = nil
                }
            }
        }
    }
}

struct BadgeCell: View {
    let badge: Badge
    @State private var bounceValue: Int = 0

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? Theme.accent : Theme.neutralFill)
                    .frame(width: 64, height: 64)
                Image(systemName: badge.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(badge.isUnlocked ? Theme.accentInk : Theme.creamTertiary)
                    .symbolEffect(.bounce, value: bounceValue)
            }
            Text(badge.name)
                .font(.caption2.weight(.medium))
                .foregroundStyle(badge.isUnlocked ? Theme.cream : Theme.creamTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .opacity(badge.isUnlocked ? 1.0 : 0.4)
        .onAppear {
            if badge.isUnlocked {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.2...0.8)) {
                    bounceValue += 1
                }
            }
        }
    }
}

struct BadgeDetailSheet: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? Theme.accent : Theme.neutralFill)
                    .frame(width: 100, height: 100)
                Image(systemName: badge.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(badge.isUnlocked ? Theme.accentInk : Theme.creamTertiary)
            }
            .padding(.top, 16)

            VStack(spacing: 8) {
                Text(badge.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.cream)
                Text(badge.description)
                    .font(.body)
                    .foregroundStyle(Theme.creamSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            if badge.isUnlocked, let date = badge.dateEarned {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.success)
                    Text("Earned \(date.formatted(.dateTime.month().day().year()))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.creamSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.success.opacity(0.1))
                .clipShape(Capsule())
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Theme.creamTertiary)
                    Text(badge.requirement)
                        .font(.subheadline)
                        .foregroundStyle(Theme.creamTertiary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct CelebrationOverlay: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.x * size.width - 4,
                    y: particle.y * size.height - 4,
                    width: 8,
                    height: 8
                )
                context.fill(
                    RoundedRectangle(cornerRadius: 2).path(in: rect),
                    with: .color(particle.color)
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            for _ in 0..<60 {
                particles.append(ConfettiParticle(
                    x: Double.random(in: 0...1),
                    y: -0.1,
                    color: [Theme.accent, Theme.flame, Theme.creamSecondary, Theme.creamTertiary].randomElement()!
                ))
            }
            withAnimation(.easeIn(duration: 2.5)) {
                for i in particles.indices {
                    particles[i].y = Double.random(in: 1.1...1.5)
                    particles[i].x += Double.random(in: -0.3...0.3)
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    let color: Color
}
