import SwiftUI

struct UpcomingClassCard: View {
    let store: MemberStore
    @State private var showingDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("UP NEXT").font(.caption.weight(.semibold)).tracking(1.5)
                Spacer()
                if store.upcomingClass != nil {
                    Text("BOOKED")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Theme.featuredFill, in: Capsule())
                }
            }
            if let next = store.upcomingClass {
                Text(next.displayName).font(.largeTitle.weight(.bold)).tracking(-1)
                VStack(alignment: .leading, spacing: 5) {
                    Text(next.date.formatted(date: .abbreviated, time: .omitted))
                    if !next.time.isEmpty { Text(next.time) }
                    if !next.instructor.isEmpty { Text("Coach \(next.instructor)") }
                }
                .font(.subheadline)
                Button { showingDetails = true } label: {
                    Label("View your class", systemImage: "arrow.up.right")
                        .frame(maxWidth: .infinity).padding(14)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.white)
                .background(Theme.accentInk, in: RoundedRectangle(cornerRadius: 14))
            } else {
                Text("Your next strong day.").font(.largeTitle.weight(.bold)).tracking(-1)
                Text("No upcoming class to show. Find your next session in Mindbody.").font(.subheadline)
                Button { store.openMindbody() } label: {
                    Label("Book a class", systemImage: "arrow.up.right")
                        .frame(maxWidth: .infinity).padding(14)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.white)
                .background(Theme.accentInk, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .foregroundStyle(Theme.accentInk)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .featuredCard()
        .sheet(isPresented: $showingDetails) {
            NavigationStack {
                if let next = store.upcomingClass {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(next.displayName).font(.title.weight(.bold))
                        Label(next.date.formatted(date: .complete, time: .omitted), systemImage: "calendar")
                        if !next.time.isEmpty { Label(next.time, systemImage: "clock") }
                        if !next.instructor.isEmpty { Label(next.instructor, systemImage: "person") }
                        Button("Open Mindbody") { store.openMindbody() }
                            .buttonStyle(.borderedProminent).tint(Theme.buttonBackground)
                            .foregroundStyle(Theme.buttonForeground)
                        Spacer(minLength: 0)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Theme.cream)
                    .background(Theme.cardBackground)
                    .navigationTitle("Your class")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingDetails = false }
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

struct WeeklyAttendanceView: View {
    let store: MemberStore
    private var days: [Date] {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        VStack(spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack { title; Spacer(); streak }
                VStack(alignment: .leading, spacing: 8) { title; streak }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 6) {
                ForEach(days, id: \.self) { date in
                    let attended = store.attendanceForDate(date) > 0
                    let today = Calendar.current.isDateInToday(date)
                    VStack(spacing: 8) {
                        Text(date.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption).foregroundStyle(Theme.creamSecondary)
                        ZStack {
                            Circle().fill(attended ? Theme.cream : today ? Theme.accent : Theme.neutralFill)
                            if attended {
                                Image(systemName: "checkmark").font(.caption.weight(.bold))
                                    .foregroundStyle(Theme.background)
                            } else {
                                Text(date.formatted(.dateTime.day())).font(.caption.weight(.semibold))
                                    .foregroundStyle(today ? Theme.accentInk : Theme.cream)
                            }
                        }
                        .aspectRatio(1, contentMode: .fit)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(date.formatted(date: .complete, time: .omitted)), \(attended ? "attended" : "no completed classes")")
                }
            }
            HStack(spacing: 0) {
                metric(store.classesThisWeek, label: "This week")
                Divider()
                metric(store.profile.classesThisMonth, label: "This month")
                Divider()
                metric(store.profile.totalClasses, label: "All time")
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 8)
            Rectangle().fill(Theme.subtleDivider).frame(height: 1)
        }
    }

    private var title: some View { Text("A little, often.").font(.title3.weight(.bold)).foregroundStyle(Theme.cream) }
    private var streak: some View {
        Label("\(store.profile.currentStreak)-day streak", systemImage: "flame")
            .font(.caption).foregroundStyle(Theme.creamSecondary)
    }
    private func metric(_ count: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(count, format: .number).font(.title.weight(.bold)).foregroundStyle(Theme.cream)
            Text(label).font(.caption).foregroundStyle(Theme.creamSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
