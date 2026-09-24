import SwiftUI

struct ChallengesView: View {
    let store: MemberStore
    var showsHeader = true
    @State private var appeared: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                if showsHeader { headerSection }

                if let active = store.challenges.first(where: { $0.isActive }) {
                    activeChallengeCard(active)
                    leaderboardSection(active)
                }

                pastChallengesSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Challenges")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(Theme.cream)
            Spacer()
        }
        .opacity(appeared ? 1 : 0)
    }

    private func activeChallengeCard(_ challenge: Challenge) -> some View {
        let progress = Double(challenge.currentCount) / Double(challenge.targetCount)
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: challenge.endDate).day ?? 0

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: challenge.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.featuredText)
                    .frame(width: 40, height: 40)
                    .background(Theme.featuredFill)
                    .clipShape(.rect(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 2) {
                    Text("ACTIVE CHALLENGE")
                        .font(.caption.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.featuredTextSecondary)
                    Text(challenge.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.featuredText)
                }
                Spacer()
                Text("\(daysLeft)d left")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.featuredText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.featuredFill)
                    .clipShape(Capsule())
            }

            Text(challenge.description)
                .font(.subheadline)
                .foregroundStyle(Theme.featuredTextSecondary)
                .lineSpacing(3)

            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.featuredFill)
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.featuredText)
                            .frame(width: geo.size.width * min(progress, 1.0), height: 10)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("\(challenge.currentCount) / \(challenge.targetCount) classes")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.featuredTextSecondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.featuredText)
                }
            }
        }
        .padding(20)
        .featuredCard()
        .opacity(appeared ? 1 : 0)
    }

    private func leaderboardSection(_ challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Leaderboard")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.cream)

            ForEach(Array(challenge.leaderboard.enumerated()), id: \.element.id) { index, entry in
                HStack(spacing: 14) {
                    Text("\(index + 1)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(index < 3 ? Theme.cream : Theme.creamTertiary)
                        .frame(width: 24)

                    ZStack {
                        Circle()
                            .fill(Theme.neutralFill)
                            .frame(width: 36, height: 36)
                        Text(entry.avatarInitials)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.creamSecondary)
                    }

                    Text(entry.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(entry.name == "Sarah M." ? Theme.cream : Theme.creamSecondary)

                    if entry.name == "Sarah M." {
                        Text("YOU")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.accentInk)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accent)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Text("\(entry.score)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.cream)
                }
                .padding(.vertical, 4)

                if index < challenge.leaderboard.count - 1 {
                    Rectangle()
                        .fill(Theme.subtleDivider)
                        .frame(height: 0.5)
                }
            }
        }
        .padding(20)
        .softCard()
        .opacity(appeared ? 1 : 0)
    }

    private var pastChallengesSection: some View {
        let past = store.challenges.filter { !$0.isActive }
        return Group {
            if !past.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Past Challenges")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.cream)

                    ForEach(past) { challenge in
                        HStack(spacing: 14) {
                            Image(systemName: challenge.icon)
                                .font(.title3)
                                .foregroundStyle(Theme.creamTertiary)
                                .frame(width: 36)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(challenge.title)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Theme.cream)
                                if let winner = challenge.winner {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trophy.fill")
                                            .font(.caption2)
                                            .foregroundStyle(Theme.creamSecondary)
                                        Text("Winner: \(winner)")
                                            .font(.caption)
                                            .foregroundStyle(Theme.creamSecondary)
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.success)
                        }
                        .padding(.vertical, 6)

                        if challenge.id != past.last?.id {
                            Rectangle()
                                .fill(Theme.subtleDivider)
                                .frame(height: 0.5)
                        }
                    }
                }
                .padding(20)
                .softCard()
                .opacity(appeared ? 1 : 0)
            }
        }
    }
}
