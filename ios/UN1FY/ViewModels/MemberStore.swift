import SwiftUI

@Observable
@MainActor
class MemberStore {
    var profile: MemberProfile
    var badges: [Badge]
    var attendanceHistory: [ClassAttendance]
    var upcomingClass: UpcomingClass?
    var challenges: [Challenge]
    var newlyUnlockedBadge: Badge?
    var mindbodyConnectionState: MindbodyConnectionState
    var mindbodyConnectionMessage: String
    var mindbodyConnectionError: String?
    var lastMindbodySync: Date?
    var showConnectionSuccess: Bool = false

    /// Drives the Home tab's community feed (auto-posts, likes, comments).
    let feed = FeedStore()

    private let mindbodyService: MindbodyService
    private let leaderboardService = SupabaseLeaderboardService()
    private let visitsService = SupabaseVisitsService()
    private var mindbodyClientId: Int?

    /// Ranked provenance of the profile's stats. A source may only overwrite
    /// numbers written by an equal or worse source — never a better one:
    /// `visits` (per-visit table, exact) > `snapshot` (nightly leaderboard,
    /// counts all past visits) > `payload` (Mindbody sync, only counts
    /// Mindbody-side check-ins, so it undercounts). This stops the sync
    /// payload from stomping correct snapshot/visits numbers moments after
    /// they render.
    private enum StatsSource: Int, Comparable {
        case none = 0, payload = 1, snapshot = 2, visits = 3

        static func < (lhs: StatsSource, rhs: StatsSource) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private var statsSource: StatsSource = .none

    /// True once the current `mindbodyClientId` has been confirmed against the
    /// studio database (a snapshot or visits row exists for it). Mindbody's own
    /// profile id can differ from the id the studio database keys visits by —
    /// a verified id must never be replaced by the sync payload's id, or every
    /// visits/snapshot lookup silently returns nothing.
    private var clientIdVerified: Bool = false

    /// A user-visible description of a data-loading problem (failed fetch, or
    /// an account we couldn't match to studio records). Shown as a banner on
    /// Home so failures are loud instead of silently showing undercounted
    /// fallback numbers. Cleared when the visits pipeline succeeds.
    var dataIssue: String?

    /// The member's all-time total from the leaderboard snapshot. Kept as a
    /// floor for the visits-derived total in case the `visits` table is ever
    /// missing part of the history.
    private var snapshotAllTime: Int?
    private var snapshotThisMonth: Int?
    private let hapticSuccess = UINotificationFeedbackGenerator()
    private let hapticError = UINotificationFeedbackGenerator()

    var isSyncing: Bool = false

    init() {
        let calendar = Calendar.current
        let now = Date()

        let savedConnected = KeychainService.isConnected
        let savedLastSync = KeychainService.lastSyncDate
        let savedClientId = KeychainService.clientId
        let savedFirstName = KeychainService.firstName ?? ""
        let savedLastName = KeychainService.lastName ?? ""

        // Personal stats start empty. They are populated only from real
        // Mindbody data (via `refreshVisits` / `refreshPersonalStatsFromLeaderboard`)
        // once the member connects — so we never show fabricated numbers to a
        // member who isn't connected yet.
        self.profile = MemberProfile(
            firstName: savedFirstName,
            lastName: savedLastName,
            memberSince: now,
            totalClasses: 0,
            currentStreak: 0,
            longestStreak: 0,
            classesThisWeek: 0,
            classesThisMonth: 0,
            classesLastMonth: 0,
            mostClassesInMonth: 0,
            monthlyGoal: 16,
            pinnedBadgeIds: [],
            hideFromLeaderboard: false,
            hideCheckIns: false,
            streakReminders: true,
            milestoneNotifications: true,
            challengeUpdates: true,
            classReminders: true
        )

        // Badges are achievements derived from real attendance; none are
        // unlocked until the member connects and their history loads.
        self.badges = Badge.allBadges

        self.attendanceHistory = []
        self.upcomingClass = nil

        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        self.challenges = [
            Challenge(
                id: "march_madness",
                title: "March Madness",
                description: "Complete 20 classes this month to earn a limited-edition badge.",
                icon: "flame.circle.fill",
                targetCount: 20,
                currentCount: 11,
                startDate: monthStart,
                endDate: monthEnd,
                isActive: true,
                leaderboard: [
                    LeaderboardEntry(id: "1", name: "Marcus T.", score: 16, avatarInitials: "MT"),
                    LeaderboardEntry(id: "2", name: "Elena R.", score: 15, avatarInitials: "ER"),
                    LeaderboardEntry(id: "3", name: "David K.", score: 14, avatarInitials: "DK"),
                    LeaderboardEntry(id: "4", name: "Priya S.", score: 13, avatarInitials: "PS"),
                    LeaderboardEntry(id: "5", name: "Sarah M.", score: 11, avatarInitials: "SM"),
                    LeaderboardEntry(id: "6", name: "Jake W.", score: 10, avatarInitials: "JW"),
                    LeaderboardEntry(id: "7", name: "Lily C.", score: 9, avatarInitials: "LC"),
                    LeaderboardEntry(id: "8", name: "Omar F.", score: 8, avatarInitials: "OF"),
                    LeaderboardEntry(id: "9", name: "Nina B.", score: 7, avatarInitials: "NB"),
                    LeaderboardEntry(id: "10", name: "Chris L.", score: 5, avatarInitials: "CL"),
                ],
                winner: nil
            ),
            Challenge(
                id: "feb_focus",
                title: "February Focus",
                description: "Hit 15 classes in February.",
                icon: "target",
                targetCount: 15,
                currentCount: 15,
                startDate: calendar.date(byAdding: .month, value: -1, to: monthStart)!,
                endDate: monthStart,
                isActive: false,
                leaderboard: [],
                winner: "Elena R."
            ),
            Challenge(
                id: "streak_week",
                title: "Streak Week",
                description: "7 days straight. No excuses.",
                icon: "bolt.horizontal.circle.fill",
                targetCount: 7,
                currentCount: 7,
                startDate: calendar.date(byAdding: .month, value: -2, to: monthStart)!,
                endDate: calendar.date(byAdding: .month, value: -1, to: monthStart)!,
                isActive: false,
                leaderboard: [],
                winner: "Marcus T."
            ),
        ]

        self.newlyUnlockedBadge = nil
        self.mindbodyConnectionState = savedConnected ? .connected : .disconnected
        self.mindbodyConnectionMessage = savedConnected
            ? "Connected. Your UN1FY account is synced with Mindbody."
            : "Connect your Mindbody account to sync bookings, attendance, and membership details."
        self.mindbodyConnectionError = nil
        self.lastMindbodySync = savedLastSync
        self.mindbodyService = MindbodyService()

        // Restore the resolved client id so a relaunch can immediately re-fetch
        // the member's visits without redoing the Mindbody OAuth login.
        self.mindbodyClientId = savedClientId
        AvatarStore.shared.configure(clientId: savedClientId)
    }

    func classCount(for type: ClassType) -> Int {
        attendanceHistory.filter { $0.classType == type }.count
    }

    func attendanceForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        return attendanceHistory.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
    }

    /// Classes completed since the start of the current week, derived from
    /// `attendanceHistory` so it stays consistent with the Stats heat map
    /// instead of relying on a static seed value.
    var classesThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return attendanceHistory.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }.count
        }
        return attendanceHistory.filter { $0.date >= weekStart && $0.date <= now }.count
    }

    var monthlyProgress: Double {
        guard profile.monthlyGoal > 0 else { return 0 }
        return min(Double(profile.classesThisMonth) / Double(profile.monthlyGoal), 1.0)
    }

    var monthComparisonDelta: Int {
        profile.classesThisMonth - profile.classesLastMonth
    }

    var isMindbodyConnected: Bool {
        mindbodyConnectionState == .connected
    }

    func connectMindbody() async {
        guard mindbodyConnectionState != .connecting else { return }

        mindbodyConnectionState = .connecting
        mindbodyConnectionError = nil
        mindbodyConnectionMessage = "Connecting to Mindbody…"

        do {
            let response = try await mindbodyService.connect()
            applyAuthResponse(response)
            await refreshPersonalStatsFromLeaderboard()
            await refreshVisits()
            persistConnection(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
            lastMindbodySync = Date()
            KeychainService.lastSyncDate = lastMindbodySync
            mindbodyConnectionState = .connected
            mindbodyConnectionMessage = response.message ?? "Connected. Your UN1FY account is synced with Mindbody."
            hapticSuccess.notificationOccurred(.success)
            showConnectionSuccess = true
            try? await Task.sleep(for: .seconds(2.5))
            showConnectionSuccess = false
        } catch {
            print("[UN1FY] connectMindbody error: \(error)")
            if let decodingError = error as? DecodingError {
                print("[UN1FY] DecodingError details: \(decodingError)")
            }
            mindbodyConnectionState = KeychainService.isConnected ? .connected : .disconnected
            hapticError.notificationOccurred(.error)
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    mindbodyConnectionError = "No internet connection. Please check your network and try again."
                case .timedOut:
                    mindbodyConnectionError = "The connection timed out. Please try again."
                case .cancelled:
                    mindbodyConnectionError = nil
                    mindbodyConnectionMessage = "Connect your Mindbody account to sync bookings, attendance, and membership details."
                    return
                default:
                    mindbodyConnectionError = "Something went wrong. Please try again."
                }
            } else if (error as NSError).domain == "com.apple.AuthenticationServices.WebAuthenticationSession",
                      (error as NSError).code == 1 {
                mindbodyConnectionError = nil
                mindbodyConnectionMessage = "Connect your Mindbody account to sync bookings, attendance, and membership details."
                return
            } else {
                mindbodyConnectionError = "Something went wrong. Please try again."
            }
            mindbodyConnectionMessage = "We couldn't finish connecting to Mindbody."
        }
    }

    func syncMindbody() async {
        guard let accessToken = KeychainService.accessToken, !accessToken.isEmpty else { return }
        guard !isSyncing else { return }

        isSyncing = true
        mindbodyConnectionError = nil

        do {
            let response = try await mindbodyService.sync(
                accessToken: accessToken,
                refreshToken: KeychainService.refreshToken,
                clientId: mindbodyClientId ?? KeychainService.clientId
            )
            applySyncResponse(response)
            await refreshPersonalStatsFromLeaderboard()
            await refreshVisits()
            if let newAccessToken = response.accessToken {
                KeychainService.accessToken = newAccessToken
            }
            if let newRefreshToken = response.refreshToken {
                KeychainService.refreshToken = newRefreshToken
            }
            lastMindbodySync = Date()
            KeychainService.lastSyncDate = lastMindbodySync
            mindbodyConnectionState = .connected
            mindbodyConnectionMessage = response.message ?? "Connected. Your UN1FY account is synced with Mindbody."
        } catch {
            mindbodyConnectionError = "Sync failed. Showing last-known data."
        }

        isSyncing = false
    }

    func refreshData() async {
        feed.configure(clientId: mindbodyClientId, memberName: leaderboardDisplayName)
        AvatarStore.shared.configure(clientId: mindbodyClientId)
        if KeychainService.isConnected {
            // Re-fetch personal data directly using the persisted client id —
            // this doesn't require the OAuth login or a valid token, so the
            // connection is restored on every relaunch. Sync runs alongside to
            // refresh tokens / name when the endpoint is reachable.
            await refreshPersonalStatsFromLeaderboard()
            await refreshVisits()
            await syncMindbody()
        } else {
            await feed.refresh()
        }
        await AvatarStore.shared.refresh()
    }

    func disconnectMindbody() {
        KeychainService.clearAll()
        mindbodyConnectionState = .disconnected
        mindbodyConnectionError = nil
        lastMindbodySync = nil
        mindbodyConnectionMessage = "Connect your Mindbody account to sync bookings, attendance, and membership details."
    }

    func openMindbody() {
        if let url = URL(string: "https://www.mindbodyonline.com") {
            UIApplication.shared.open(url)
        }
    }

    private func persistConnection(accessToken: String?, refreshToken: String?) {
        if let accessToken, !accessToken.isEmpty {
            KeychainService.accessToken = accessToken
        }
        if let refreshToken, !refreshToken.isEmpty {
            KeychainService.refreshToken = refreshToken
        }
        KeychainService.isConnected = true
        persistMemberIdentity()
    }

    /// Persists the resolved client id and name so the connection (and the
    /// ability to re-fetch personal data) survives app relaunches.
    private func persistMemberIdentity() {
        if let clientId = mindbodyClientId {
            KeychainService.clientId = clientId
        }
        if !profile.firstName.isEmpty {
            KeychainService.firstName = profile.firstName
        }
        if !profile.lastName.isEmpty {
            KeychainService.lastName = profile.lastName
        }
    }

    private func applyAuthResponse(_ response: MindbodyAuthExchangeResponse) {
        applyMemberPayload(response.member)
        // Visits are the single source of truth for the Next Class card, so
        // don't set `upcomingClass` from the auth payload here. The payload's
        // attendance history only includes Mindbody-side check-ins, so it
        // must never replace the visits-derived history.
        if statsSource < .visits, let history = response.attendanceHistory, !history.isEmpty {
            attendanceHistory = history
        }
    }

    private func applySyncResponse(_ response: MindbodySyncResponse) {
        applyMemberPayload(response.member)
        // `upcomingClass` is intentionally NOT set here — the visits table
        // (set by `refreshVisits`) is the single source of truth. Same rule
        // for attendance history: the payload only counts Mindbody-side
        // check-ins, so it's a bootstrap until visits load.
        if statsSource < .visits, let history = response.attendanceHistory, !history.isEmpty {
            attendanceHistory = history
        }
    }

    /// Builds the member's leaderboard display name (e.g. "Julie R.") to match
    /// against `leaderboard_snapshot`, same format the Ranks tab uses.
    private var leaderboardDisplayName: String {
        let first = profile.firstName
        let lastInitial = profile.lastName.first.map { String($0) } ?? ""
        guard !first.isEmpty else { return "" }
        return lastInitial.isEmpty ? first : "\(first) \(lastInitial)."
    }

    /// Pulls the member's real numbers (all-time total, classes this month,
    /// current streak) from the same `leaderboard_snapshot` data that powers the
    /// Ranks tab, and merges them into the profile. Only overrides values when a
    /// matching row is found, so members who aren't on the boards keep the
    /// existing data. Requires the member to rank in a board's top 25.
    func refreshPersonalStatsFromLeaderboard() async {
        let name = leaderboardDisplayName
        guard mindbodyClientId != nil || !name.isEmpty else { return }

        do {
            var rows = try await leaderboardService.fetchMemberRows(
                displayName: name,
                clientId: mindbodyClientId
            )

            // Self-heal a wrong client id: the id Mindbody's profile reports
            // can differ from the id the studio database keys visits by. If the
            // id-based lookup finds nothing, retry by display name and adopt
            // the id the snapshot actually uses.
            if rows.isEmpty, mindbodyClientId != nil, !name.isEmpty {
                rows = try await leaderboardService.fetchMemberRows(
                    displayName: name,
                    clientId: nil
                )
                if let resolved = rows.first?.clientId {
                    print("[UN1FY] client id corrected via name match: \(mindbodyClientId.map(String.init) ?? "nil") -> \(resolved)")
                }
            }
            guard !rows.isEmpty else { return }

            // The snapshot rows carry the studio-side client_id — adopt it both
            // when the auth payload didn't include an id and when it included a
            // different (Mindbody-profile) id, then persist so relaunches use
            // the verified id straight away.
            if let resolved = rows.first?.clientId, resolved != mindbodyClientId {
                mindbodyClientId = resolved
            }
            if let verified = mindbodyClientId {
                clientIdVerified = true
                KeychainService.clientId = verified
            }

            // Remember the snapshot totals as a floor for the visits-derived
            // numbers, even when the snapshot doesn't get applied directly.
            for row in rows {
                switch row.period {
                case LeaderboardPeriod.allTime.rawValue:
                    snapshotAllTime = row.value
                case LeaderboardPeriod.month.rawValue:
                    snapshotThisMonth = row.value
                default:
                    break
                }
            }

            // Once visit-derived stats exist they win — the snapshot is only a
            // bootstrap for members whose visit history hasn't loaded yet.
            guard statsSource < .visits else { return }

            for row in rows {
                switch row.period {
                case LeaderboardPeriod.allTime.rawValue:
                    profile.totalClasses = row.value
                case LeaderboardPeriod.month.rawValue:
                    profile.classesThisMonth = row.value
                case LeaderboardPeriod.streak.rawValue:
                    profile.currentStreak = row.value
                    profile.longestStreak = max(profile.longestStreak, row.value)
                default:
                    break
                }
            }
            statsSource = max(statsSource, .snapshot)
        } catch {
            print("[UN1FY] Personal stats from leaderboard failed: \(error)")
        }
    }

    /// Pulls the member's complete per-visit history from the Supabase `visits`
    /// table and derives the real attendance heat map, class breakdown, and the
    /// counts shown on Home/Stats (total, this week, this/last month, best
    /// month, streaks). Requires a resolved Mindbody `client_id`.
    func refreshVisits() async {
        guard let clientId = mindbodyClientId else { return }

        do {
            let visits = try await visitsService.fetchVisits(clientId: clientId)
            // A visit counts as attended once its class time has passed. The
            // `signed_in` flag can lag behind in the visits table (past classes
            // often still show signed_in = false), which undercounted stats —
            // the leaderboard counts all past visits, so we match it. Compare in
            // the same tagged-UTC wall-clock frame the class times are stored
            // in. Mindbody also emits duplicate rows per class, so dedupe by
            // the class occurrence to avoid double-counting one attendance.
            let nowTagged = Date().addingTimeInterval(TimeInterval(TimeZone.current.secondsFromGMT()))
            let attendedVisits = visits.filter { visit in
                guard let date = visit.date else { return false }
                return date <= nowTagged
            }
            var seen = Set<String>()
            let dedupedVisits = attendedVisits.filter { visit in
                let key = "\(visit.classId ?? visit.id)-\(visit.visitDate)"
                return seen.insert(key).inserted
            }
            let attendance = dedupedVisits
                .compactMap { $0.toAttendance() }
                .sorted { $0.date > $1.date }

            // Rows exist for this id, so it's the id the studio database uses —
            // lock it in so the sync payload can't swap it back.
            if !visits.isEmpty {
                clientIdVerified = true
                KeychainService.clientId = clientId
            }

            // Derive the Next Class card from the soonest future booking in the
            // `visits` table, using that row's own `class_name`.
            applyUpcomingClass(from: visits)

            // Auto-post any classes completed in the last 48 hours to the
            // community feed (deduped server-side by visit_key), then reload it.
            feed.configure(clientId: clientId, memberName: leaderboardDisplayName)
            AvatarStore.shared.configure(clientId: clientId)
            await feed.syncCompletedClasses(from: visits)

            guard !attendance.isEmpty else {
                if visits.isEmpty {
                    dataIssue = "We couldn't match your account to the studio's visit records yet. Pull down to refresh, or reconnect Mindbody in Settings."
                }
                return
            }

            attendanceHistory = attendance
            applyDerivedStats(from: attendance)
            evaluateBadges()
            dataIssue = nil
            print("[UN1FY] visits refresh: rows=\(visits.count) attended=\(dedupedVisits.count) thisMonth=\(profile.classesThisMonth)")
        } catch {
            print("[UN1FY] Visits fetch failed: \(error)")
            if statsSource < .visits {
                dataIssue = "Couldn't load your visit history. Pull down to refresh."
            }
        }
    }

    /// Recomputes every badge's unlock state as a pure function of the member's
    /// real attendance (`attendanceHistory`) and derived totals (`profile`).
    /// Already-earned badges keep their original `dateEarned` and never
    /// re-lock (e.g. a broken streak doesn't revoke a streak badge, since we
    /// evaluate against `longestStreak`). When a badge flips from locked to
    /// unlocked, the most significant one is surfaced via `newlyUnlockedBadge`
    /// so the Achievements tab can celebrate it.
    private func evaluateBadges() {
        // Studio wall-clock calendar: Mindbody emits class times tagged as UTC
        // (a 5:30 PM class is "17:30:00+00:00"), so reading hour/weekday/month
        // components in UTC yields the real local class time the member saw.
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC") ?? .current

        let totalClasses = profile.totalClasses
        let longestStreak = profile.longestStreak

        // Group attended classes by ISO week to evaluate variety badges, and by
        // calendar month to count weekend classes.
        var weeklyTypes: [Int: Set<ClassType>] = [:]
        var weekendByMonth: [DateComponents: Int] = [:]
        var hasEarlyBird = false
        var hasNightOwl = false

        for entry in attendanceHistory {
            let comps = utcCalendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear, .year, .month, .weekday, .hour],
                from: entry.date
            )

            if let year = comps.yearForWeekOfYear, let week = comps.weekOfYear {
                let key = year * 100 + week
                weeklyTypes[key, default: []].insert(entry.classType)
            }

            if let weekday = comps.weekday, weekday == 1 || weekday == 7 {
                let monthKey = DateComponents(year: comps.year, month: comps.month)
                weekendByMonth[monthKey, default: 0] += 1
            }

            if let hour = comps.hour {
                if hour < 6 { hasEarlyBird = true }
                if hour >= 19 { hasNightOwl = true }
            }
        }

        let hasBalancedWeek = weeklyTypes.values.contains { types in
            types.contains(.power35) && types.contains(.sculpt45)
        }
        let hasTripleThreatWeek = weeklyTypes.values.contains { types in
            types.contains(.power35) && types.contains(.sculpt45) && types.contains(.runClub)
        }
        let hasWeekendWarrior = weekendByMonth.values.contains { $0 >= 4 }

        func isEarned(_ id: String) -> Bool {
            switch id {
            case "first_class": return totalClasses >= 1
            case "ten_classes": return totalClasses >= 10
            case "twenty_five_classes": return totalClasses >= 25
            case "fifty_classes": return totalClasses >= 50
            case "hundred_classes": return totalClasses >= 100
            case "two_fifty_classes": return totalClasses >= 250
            case "streak_7": return longestStreak >= 7
            case "streak_14": return longestStreak >= 14
            case "streak_30": return longestStreak >= 30
            case "streak_60": return longestStreak >= 60
            case "streak_90": return longestStreak >= 90
            case "balanced": return hasBalancedWeek
            case "triple_threat": return hasTripleThreatWeek
            case "early_bird": return hasEarlyBird
            case "night_owl": return hasNightOwl
            case "weekend_warrior": return hasWeekendWarrior
            default: return false
            }
        }

        let now = Date()
        var firstNewlyUnlocked: Badge?

        for index in badges.indices {
            let wasUnlocked = badges[index].isUnlocked
            let earned = isEarned(badges[index].id)
            guard earned else { continue }

            badges[index].isUnlocked = true
            if badges[index].dateEarned == nil {
                badges[index].dateEarned = now
            }
            if !wasUnlocked, firstNewlyUnlocked == nil {
                firstNewlyUnlocked = badges[index]
            }
        }

        if let firstNewlyUnlocked {
            newlyUnlockedBadge = firstNewlyUnlocked
            hapticSuccess.notificationOccurred(.success)
        }
    }

    /// Picks the soonest future booking from the member's visits and surfaces it
    /// in the Home "Next Class" card, using that booking row's `class_name`.
    private func applyUpcomingClass(from visits: [Visit]) {
        // Mindbody stores the studio's wall-clock class time tagged as UTC (a
        // 5:30 PM class is parsed to 17:30 UTC). Compare against "now" expressed
        // in the same tagged-UTC frame — i.e. the device's local wall-clock
        // labeled UTC — so an evening class at a studio behind UTC isn't wrongly
        // treated as already past.
        let now = Date().addingTimeInterval(TimeInterval(TimeZone.current.secondsFromGMT()))

        // A booking is still "upcoming" only if it hasn't started yet AND the
        // member hasn't already signed in (attended). Once today's class is
        // completed (signed_in == true), it drops off so the card advances to
        // the next future booking — e.g. tomorrow's class.
        let nextBooking = visits
            .filter { ($0.date ?? .distantPast) > now && $0.signedIn != true }
            .min { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }

        guard let nextBooking, let date = nextBooking.date else {
            upcomingClass = nil
            return
        }

        let resolvedName = nextBooking.className
            .flatMap { $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 }

        let resolvedType: ClassType = {
            if let resolvedName {
                let lower = resolvedName.lowercased()
                if lower.contains("power") { return .power35 }
                if lower.contains("sculpt") { return .sculpt45 }
                if lower.contains("run") { return .runClub }
            }
            return nextBooking.classType
        }()

        upcomingClass = UpcomingClass(
            classType: resolvedType,
            date: date,
            time: nextBooking.timeString,
            instructor: "",
            name: resolvedName
        )
    }

    /// Recomputes the profile's class counts and streaks from real attendance.
    private func applyDerivedStats(from attendance: [ClassAttendance]) {
        let calendar = Calendar.current
        let now = Date()

        statsSource = .visits
        // The nightly snapshot counts the member's full history, so it acts as
        // a floor in case the visits table is missing older rows.
        profile.totalClasses = max(attendance.count, snapshotAllTime ?? 0)

        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: monthStart)!
        let derivedThisMonth = attendance.filter { $0.date >= monthStart && $0.date <= now }.count
        profile.classesThisMonth = max(derivedThisMonth, snapshotThisMonth ?? 0)
        profile.classesLastMonth = attendance.filter { $0.date >= lastMonthStart && $0.date < monthStart }.count

        // Best month: highest count across any calendar month in the history.
        var monthCounts: [DateComponents: Int] = [:]
        for entry in attendance {
            let comps = calendar.dateComponents([.year, .month], from: entry.date)
            monthCounts[comps, default: 0] += 1
        }
        if let best = monthCounts.values.max() {
            profile.mostClassesInMonth = max(best, profile.classesThisMonth)
        }

        let streaks = computeStreaks(from: attendance, calendar: calendar, now: now)
        profile.currentStreak = streaks.current
        profile.longestStreak = max(profile.longestStreak, streaks.longest)
    }

    /// Computes current and longest streaks measured in consecutive days that
    /// have at least one attended class.
    private func computeStreaks(
        from attendance: [ClassAttendance],
        calendar: Calendar,
        now: Date
    ) -> (current: Int, longest: Int) {
        let days = Set(attendance.map { calendar.startOfDay(for: $0.date) }).sorted()
        guard !days.isEmpty else { return (0, 0) }

        var longest = 1
        var run = 1
        for index in 1..<max(days.count, 1) where days.count > 1 {
            let prev = days[index - 1]
            let curr = days[index]
            if let diff = calendar.dateComponents([.day], from: prev, to: curr).day, diff == 1 {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }

        // Current streak: count back from today (or yesterday) while days are
        // consecutive. Allows today to be a rest day without breaking it.
        let today = calendar.startOfDay(for: now)
        let attendedDays = Set(days)
        var current = 0
        var cursor = today
        if !attendedDays.contains(today) {
            cursor = calendar.date(byAdding: .day, value: -1, to: today)!
        }
        while attendedDays.contains(cursor) {
            current += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }

        return (current, longest)
    }

    private func applyMemberPayload(_ member: MindbodyMemberPayload?) {
        guard let member else { return }
        // The payload's id comes from Mindbody's profile and can differ from
        // the id the studio database keys visits by. Only accept it while the
        // current id is unverified — once a snapshot/visits row confirms the
        // id, the payload must not swap it back to the wrong one.
        if let clientId = member.clientId, !clientIdVerified {
            mindbodyClientId = clientId
        }
        if let firstName = member.firstName, !firstName.isEmpty {
            profile.firstName = firstName
        }
        if let lastName = member.lastName, !lastName.isEmpty {
            profile.lastName = lastName
        }
        if let memberSince = member.memberSince {
            profile.memberSince = memberSince
        }
        // Stats from the sync payload only count Mindbody-side check-ins, which
        // lag behind real attendance. They're the lowest-priority bootstrap —
        // once stats come from the leaderboard snapshot or the visits table,
        // the payload must not overwrite them.
        if statsSource <= .payload {
            if let totalClasses = member.totalClasses {
                profile.totalClasses = totalClasses
            }
            if let currentStreak = member.currentStreak {
                profile.currentStreak = currentStreak
            }
            if let longestStreak = member.longestStreak {
                profile.longestStreak = longestStreak
            }
            if let classesThisWeek = member.classesThisWeek {
                profile.classesThisWeek = classesThisWeek
            }
            if let classesThisMonth = member.classesThisMonth {
                profile.classesThisMonth = classesThisMonth
            }
            if let classesLastMonth = member.classesLastMonth {
                profile.classesLastMonth = classesLastMonth
            }
            if let mostClassesInMonth = member.mostClassesInMonth {
                profile.mostClassesInMonth = mostClassesInMonth
            }
            statsSource = max(statsSource, .payload)
        } else {
            print("[UN1FY] sync payload stats skipped (source=\(statsSource))")
        }
        if let monthlyGoal = member.monthlyGoal {
            profile.monthlyGoal = monthlyGoal
        }
        // `member.nextClass` is intentionally ignored — visits drive the Next
        // Class card; the edge function value is only a fallback.
    }
}
