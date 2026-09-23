import Foundation
import HealthKit

/// Reads active-energy (calorie) data from Apple Health so completed classes
/// can auto-post with the member's real burn. All methods degrade gracefully
/// when Health data is unavailable (e.g. the cloud simulator) or permission is
/// denied — posts simply omit calories.
nonisolated final class HealthKitService: Sendable {
    private let store = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Requests read access to active energy burned. Returns whether the
    /// request completed (the user may still have denied access — queries then
    /// return no data, which we treat as "no calories").
    func requestReadAccess() async -> Bool {
        guard isAvailable else { return false }
        let type = HKQuantityType(.activeEnergyBurned)
        do {
            try await store.requestAuthorization(toShare: [], read: [type])
            return true
        } catch {
            print("[UN1FY] HealthKit authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Sums active calories burned in the given real-time window, rounded to
    /// a whole number. Returns nil when there is no data.
    func activeCalories(start: Date, end: Date) async -> Int? {
        guard isAvailable, end > start else { return nil }
        let type = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let kilocalories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie())
                if let kilocalories, kilocalories >= 1 {
                    continuation.resume(returning: Int(kilocalories.rounded()))
                } else {
                    continuation.resume(returning: nil)
                }
            }
            store.execute(query)
        }
    }
}
