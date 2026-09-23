import SwiftUI

@Observable
@MainActor
final class LeaderboardStore {
    var selectedPeriod: LeaderboardPeriod = .month
    var rowsByPeriod: [LeaderboardPeriod: [LeaderboardRow]] = [:]
    var isLoading: Bool = false
    var errorMessage: String?
    var lastUpdated: Date?

    private let service: SupabaseLeaderboardService

    init(service: SupabaseLeaderboardService = SupabaseLeaderboardService()) {
        self.service = service
    }

    var currentRows: [LeaderboardRow] {
        rowsByPeriod[selectedPeriod] ?? []
    }

    /// Loads the currently selected board. Shows a spinner only when there's no
    /// cached data for that period yet.
    func load(period: LeaderboardPeriod? = nil) async {
        let target = period ?? selectedPeriod
        if rowsByPeriod[target] == nil {
            isLoading = true
        }
        errorMessage = nil

        do {
            let rows = try await service.fetchBoard(period: target)
            rowsByPeriod[target] = rows
            lastUpdated = rows.first?.generatedAt ?? Date()
        } catch {
            print("[UN1FY] Leaderboard load failed: \(error)")
            if rowsByPeriod[target] == nil {
                errorMessage = "Couldn't load the leaderboard. Pull to refresh to try again."
            }
        }

        isLoading = false
    }

    /// Force-refreshes every board (used for pull-to-refresh).
    func refreshAll() async {
        await load(period: selectedPeriod)
    }
}
