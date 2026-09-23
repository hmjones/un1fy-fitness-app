import Foundation

nonisolated struct MindbodyAuthExchangeResponse: Codable, Sendable {
    let message: String?
    let accessToken: String?
    let refreshToken: String?
    let member: MindbodyMemberPayload?
    let nextClass: UpcomingClass?
    let attendanceHistory: [ClassAttendance]?

    private enum CodingKeys: String, CodingKey {
        case message, accessToken, refreshToken, member, nextClass, attendanceHistory
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try? container.decode(String.self, forKey: .message)
        self.accessToken = try? container.decode(String.self, forKey: .accessToken)
        self.refreshToken = try? container.decode(String.self, forKey: .refreshToken)
        self.member = try? container.decode(MindbodyMemberPayload.self, forKey: .member)
        self.nextClass = try? container.decode(UpcomingClass.self, forKey: .nextClass)
        self.attendanceHistory = try? container.decode([ClassAttendance].self, forKey: .attendanceHistory)
    }
}

nonisolated struct MindbodyMemberPayload: Codable, Sendable {
    let clientId: Int?
    let firstName: String?
    let lastName: String?
    let memberSince: Date?
    let totalClasses: Int?
    let currentStreak: Int?
    let longestStreak: Int?
    let classesThisWeek: Int?
    let classesThisMonth: Int?
    let classesLastMonth: Int?
    let mostClassesInMonth: Int?
    let monthlyGoal: Int?
    let nextClass: UpcomingClass?

    private enum CodingKeys: String, CodingKey {
        case clientId, firstName, lastName, memberSince, totalClasses, currentStreak, longestStreak
        case classesThisWeek, classesThisMonth, classesLastMonth, mostClassesInMonth, monthlyGoal, nextClass
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clientId = Self.decodeFlexibleInt(container: container, key: .clientId)
        self.firstName = try? container.decode(String.self, forKey: .firstName)
        self.lastName = try? container.decode(String.self, forKey: .lastName)
        self.memberSince = try? container.decode(Date.self, forKey: .memberSince)
        self.totalClasses = Self.decodeFlexibleInt(container: container, key: .totalClasses)
        self.currentStreak = Self.decodeFlexibleInt(container: container, key: .currentStreak)
        self.longestStreak = Self.decodeFlexibleInt(container: container, key: .longestStreak)
        self.classesThisWeek = Self.decodeFlexibleInt(container: container, key: .classesThisWeek)
        self.classesThisMonth = Self.decodeFlexibleInt(container: container, key: .classesThisMonth)
        self.classesLastMonth = Self.decodeFlexibleInt(container: container, key: .classesLastMonth)
        self.mostClassesInMonth = Self.decodeFlexibleInt(container: container, key: .mostClassesInMonth)
        self.monthlyGoal = Self.decodeFlexibleInt(container: container, key: .monthlyGoal)
        self.nextClass = try? container.decode(UpcomingClass.self, forKey: .nextClass)
    }

    private static func decodeFlexibleInt(container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Int? {
        if let intVal = try? container.decode(Int.self, forKey: key) {
            return intVal
        }
        if let strVal = try? container.decode(String.self, forKey: key), let parsed = Int(strVal) {
            return parsed
        }
        if let doubleVal = try? container.decode(Double.self, forKey: key) {
            return Int(doubleVal)
        }
        return nil
    }
}

nonisolated struct MindbodyAuthStartResponse: Codable, Sendable {
    let authorizationURL: URL
}

nonisolated struct MindbodyAuthExchangeRequest: Codable, Sendable {
    let code: String
    let state: String?
    let redirectURI: String
}

nonisolated struct MindbodySyncRequest: Codable, Sendable {
    let accessToken: String
    let refreshToken: String?
    /// The member's resolved Mindbody client id, so the sync function can fetch
    /// the correct member's live next class.
    let clientId: Int?
    /// The device's current offset from UTC, in seconds (e.g. -14400 for US
    /// Eastern in summer). Mindbody emits class times as the studio's wall-clock
    /// hour tagged as UTC, so the function needs this offset to decide whether a
    /// class is still in the future in the member's local time — otherwise an
    /// evening class at a studio behind UTC is wrongly treated as already past.
    let timezoneOffsetSeconds: Int?
}

nonisolated struct MindbodySyncResponse: Codable, Sendable {
    let message: String?
    let accessToken: String?
    let refreshToken: String?
    let member: MindbodyMemberPayload?
    let nextClass: UpcomingClass?
    let attendanceHistory: [ClassAttendance]?

    private enum CodingKeys: String, CodingKey {
        case message, accessToken, refreshToken, member, nextClass, attendanceHistory
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try? container.decode(String.self, forKey: .message)
        self.accessToken = try? container.decode(String.self, forKey: .accessToken)
        self.refreshToken = try? container.decode(String.self, forKey: .refreshToken)
        self.member = try? container.decode(MindbodyMemberPayload.self, forKey: .member)
        self.nextClass = try? container.decode(UpcomingClass.self, forKey: .nextClass)
        self.attendanceHistory = try? container.decode([ClassAttendance].self, forKey: .attendanceHistory)
    }
}
