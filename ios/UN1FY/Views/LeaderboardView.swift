import SwiftUI

struct LeaderboardView: View {
    let memberStore: MemberStore
    var showsHeader = true
    @State private var store = LeaderboardStore()
    @State private var appeared: Bool = false

    private var myDisplayName: String {
        let first = memberStore.profile.firstName
        let lastInitial = memberStore.profile.lastName.first.map { String($0) } ?? ""
        guard !first.isEmpty else { return "" }
        return lastInitial.isEmpty ? first : "\(first) \(lastInitial)."
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if showsHeader { headerSection }
                periodPicker

                if store.isLoading && store.currentRows.isEmpty {
                    loadingState
                } else if let error = store.errorMessage, store.currentRows.isEmpty {
                    errorState(error)
                } else if store.currentRows.isEmpty {
                    emptyState
                } else {
                    topThreeSection
                    listSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Theme.background.ignoresSafeArea())
        .refreshable {
            await store.refreshAll()
            await AvatarStore.shared.refresh()
        }
        .task {
            await AvatarStore.shared.loadIfNeeded()
            await store.load()
        }
        .onChange(of: store.selectedPeriod) { _, newValue in
            Task { await store.load(period: newValue) }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Leaderboard")
                    .font(.system(.largeTitle, weight: .bold))
                    .foregroundStyle(Theme.cream)
                Spacer()
            }
            if let updated = store.lastUpdated {
                Text("Updated \(updated.formatted(.relative(presentation: .named)))")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.creamTertiary)
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private var periodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LeaderboardPeriod.allCases) { period in
                    let isSelected = store.selectedPeriod == period
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            store.selectedPeriod = period
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: period.icon)
                                .font(.caption.weight(.semibold))
                            Text(period.title)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(isSelected ? Theme.buttonForeground : Theme.creamSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(isSelected ? Theme.buttonBackground : Theme.cardBackground)
                                .overlay(
                                    Capsule().stroke(Theme.cardBorder, lineWidth: isSelected ? 0 : 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private var topThreeSection: some View {
        let top = Array(store.currentRows.prefix(3))
        return VStack(spacing: 0) {
            ForEach(Array(top.enumerated()), id: \.element.id) { index, row in
                topRowView(row)
                if index < top.count - 1 {
                    Rectangle()
                        .fill(Theme.featuredFill)
                        .frame(height: 0.5)
                        .padding(.leading, 58)
                }
            }
        }
        .padding(.vertical, 6)
        .featuredCard()
        .opacity(appeared ? 1 : 0)
    }

    private func topRowView(_ row: LeaderboardRow) -> some View {
        let isMe = !myDisplayName.isEmpty && row.displayName == myDisplayName

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(row.rank == 1 ? Theme.featuredText : Theme.featuredFill)
                    .frame(width: 28, height: 28)
                Text("\(row.rank)")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(row.rank == 1 ? Theme.featuredBackground : Theme.featuredText)
            }

            AvatarView(
                clientId: row.clientId,
                initials: row.avatarInitials,
                size: 40,
                fill: Theme.featuredFill,
                accent: Theme.featuredText
            )

            Text(row.displayName)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.featuredText)
                .lineLimit(1)

            if row.rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.featuredTextSecondary)
            }

            if isMe {
                Text("YOU")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.featuredBackground)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.featuredText)
                    .clipShape(Capsule())
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(row.value)")
                    .font(.system(.title3, weight: .black))
                    .foregroundStyle(Theme.featuredText)
                Text(store.selectedPeriod.unit)
                    .font(.caption2)
                    .foregroundStyle(Theme.featuredTextTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var listSection: some View {
        let rest = Array(store.currentRows.dropFirst(3))
        return Group {
            if !rest.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(rest.enumerated()), id: \.element.id) { index, row in
                        rowView(row)
                        if index < rest.count - 1 {
                            Rectangle()
                                .fill(Theme.subtleDivider)
                                .frame(height: 0.5)
                                .padding(.leading, 54)
                        }
                    }
                }
                .padding(.vertical, 6)
                .softCard()
                .opacity(appeared ? 1 : 0)
            }
        }
    }

    private func rowView(_ row: LeaderboardRow) -> some View {
        let isMe = !myDisplayName.isEmpty && row.displayName == myDisplayName

        return HStack(spacing: 14) {
            Text("\(row.rank)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.creamTertiary)
                .frame(width: 24)

            AvatarView(
                clientId: row.clientId,
                initials: row.avatarInitials,
                size: 36
            )

            Text(row.displayName)
                .font(.body.weight(.medium))
                .foregroundStyle(isMe ? Theme.cream : Theme.creamSecondary)

            if isMe {
                Text("YOU")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.accentInk)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accent)
                    .clipShape(Capsule())
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(row.value)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.cream)
                Text(store.selectedPeriod.unit)
                    .font(.caption2)
                    .foregroundStyle(Theme.creamTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(Theme.creamTertiary)
            Text("Loading leaderboard…")
                .font(.subheadline)
                .foregroundStyle(Theme.creamSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(Theme.creamTertiary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.creamSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy")
                .font(.largeTitle)
                .foregroundStyle(Theme.creamTertiary)
            Text("No rankings yet for this board.")
                .font(.subheadline)
                .foregroundStyle(Theme.creamSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
