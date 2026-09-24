import SwiftUI

struct ProgressOverview: View {
    let store: MemberStore
    @State private var period: Period = .month

    private enum Period: String, CaseIterable {
        case month = "This month", allTime = "All time"
    }

    private var months: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        return (-5...0).compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: offset, to: start) else { return nil }
            let count: Int
            if offset == 0 {
                count = store.profile.classesThisMonth
            } else if offset == -1 {
                count = store.profile.classesLastMonth
            } else {
                count = store.attendanceHistory.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }.count
            }
            return (date: month, count: count)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Picker("Progress period", selection: $period) {
                ForEach(Period.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            VStack(alignment: .leading, spacing: 12) {
                Text(period == .month ? "\(Date().formatted(.dateTime.month(.wide)).uppercased()) CLASSES" : "TOTAL CLASSES")
                    .font(.caption.weight(.semibold)).tracking(1.5)
                    .foregroundStyle(Theme.creamSecondary)
                Text(period == .month ? store.profile.classesThisMonth : store.profile.totalClasses, format: .number)
                    .font(.system(.largeTitle, weight: .bold)).monospacedDigit()
                    .foregroundStyle(Theme.cream)
                Text(period == .month ? "\(store.profile.classesThisMonth) of \(store.profile.monthlyGoal) classes toward your monthly goal" : "Building strength, one class at a time.")
                    .font(.subheadline).foregroundStyle(Theme.creamSecondary)
                if period == .month {
                    ProgressView(value: store.monthlyProgress)
                        .tint(Theme.accent)
                        .accessibilityLabel("Monthly class goal")
                }
                Text("Last six months").font(.caption).foregroundStyle(Theme.creamSecondary)
                    .padding(.top, 8)
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(months, id: \.date) { month in
                        VStack(spacing: 8) {
                            Text(month.count, format: .number).font(.caption).monospacedDigit()
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Calendar.current.isDate(month.date, equalTo: Date(), toGranularity: .month) ? Theme.accent : Theme.neutralFill)
                                .frame(height: max(4, 100 * CGFloat(month.count) / CGFloat(max(months.map(\.count).max() ?? 0, 1))))
                            Text(month.date.formatted(.dateTime.month(.abbreviated))).font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(month.date.formatted(.dateTime.month(.wide).year())), \(month.count) classes")
                    }
                }
                .foregroundStyle(Theme.creamSecondary)
            }
            .padding(22)
            .softCard()
        }
    }
}

struct ProgressBadgesSection: View {
    let store: MemberStore
    private var nextMilestone: Int? {
        [1, 10, 25, 50, 100, 250].first { $0 > store.profile.totalClasses }
    }
    private var earned: [Badge] { store.badges.filter(\.isUnlocked) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let target = nextMilestone {
                Text("Your next milestone").font(.title3.weight(.bold))
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("The \(target) club").font(.headline)
                            Text("\(target - store.profile.totalClasses) classes to your next milestone badge")
                                .font(.subheadline).foregroundStyle(Theme.creamSecondary)
                        }
                        Spacer()
                        Image(systemName: "medal").font(.title2).foregroundStyle(Theme.accentText)
                    }
                    ProgressView(value: Double(store.profile.totalClasses), total: Double(target))
                        .tint(Theme.accent)
                        .accessibilityLabel("Milestone progress")
                    Text("\(store.profile.totalClasses) of \(target) classes").font(.caption).foregroundStyle(Theme.creamSecondary)
                }
                .padding(20).softCard()
            }
            NavigationLink {
                AchievementsView(store: store)
                    .navigationTitle("Badges")
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Earned, not given.").font(.title3.weight(.bold))
                        Text("\(earned.count) badges · View all").font(.caption).foregroundStyle(Theme.creamSecondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .frame(minHeight: 44)
            }
            .accessibilityIdentifier("progress.badges")
            if !earned.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(Array(earned.prefix(3))) { badge in
                        NavigationLink { BadgeDetailSheet(badge: badge) } label: {
                            VStack(spacing: 10) {
                                Image(systemName: badge.icon)
                                    .font(.title2)
                                    .frame(width: 56, height: 56)
                                    .background(Theme.neutralFill, in: Circle())
                                Text(badge.name).font(.caption).multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .foregroundStyle(Theme.cream)
    }
}
