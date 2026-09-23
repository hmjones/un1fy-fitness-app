import Foundation

/// A single attendance row from the Supabase `visits` table, refreshed nightly
/// by the Vercel cron that pulls from Mindbody. Keyed by `client_id`.
nonisolated struct Visit: Identifiable, Codable, Sendable {
    let id: Int
    let clientId: Int
    let classId: Int?
    let className: String?
    let visitDate: String
    let visitDatetime: String?
    let signedIn: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case classId = "class_id"
        case className = "class_name"
        case visitDate = "visit_date"
        case visitDatetime = "visit_datetime"
        case signedIn = "signed_in"
    }

    /// Maps the free-text Mindbody class name to one of the app's `ClassType`s.
    var classType: ClassType {
        guard let name = className?.lowercased() else { return .other }
        if name.contains("power") { return .power35 }
        if name.contains("sculpt") { return .sculpt45 }
        if name.contains("run") { return .runClub }
        return .other
    }

    /// The visit's calendar date, parsed from `visit_datetime` (preferred) or
    /// the date-only `visit_date` column.
    var date: Date? {
        if let parsed = parsedDatetime {
            return parsed
        }
        return Visit.dayFormatter.date(from: visitDate)
    }

    /// A friendly time string (e.g. "8:30 AM") derived from `visit_datetime`.
    var timeString: String {
        guard let parsed = parsedDatetime else { return "" }
        return Visit.displayTimeFormatter.string(from: parsed)
    }

    /// Parses `visit_datetime`, tolerating values both with and without
    /// fractional seconds (Mindbody emits e.g. "2026-06-17T17:30:00+00:00").
    private var parsedDatetime: Date? {
        guard let visitDatetime else { return nil }
        if let parsed = Visit.isoFormatter.date(from: visitDatetime) {
            return parsed
        }
        return Visit.isoFormatterNoFraction.date(from: visitDatetime)
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let displayTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        // Mindbody stores the studio's wall-clock class time but tags it as UTC
        // (e.g. a 5:30 PM class is emitted as "17:30:00+00:00"). Format in UTC
        // so we display the real class time instead of shifting it to the
        // device's local timezone.
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    /// Converts this visit into the app's `ClassAttendance` model used by the
    /// Stats heat map and class breakdown.
    func toAttendance() -> ClassAttendance? {
        guard let date else { return nil }
        return ClassAttendance(
            id: String(id),
            classType: classType,
            date: date,
            time: timeString,
            instructor: ""
        )
    }

    /// Converts this visit (a future booking) into the app's `UpcomingClass`
    /// model shown in the Home "Next Class" card.
    func toUpcomingClass() -> UpcomingClass? {
        guard let date else { return nil }
        return UpcomingClass(
            classType: classType,
            date: date,
            time: timeString,
            instructor: "",
            name: className
        )
    }
}
