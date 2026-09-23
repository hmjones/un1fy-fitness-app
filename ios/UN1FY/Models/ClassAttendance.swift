import Foundation

nonisolated struct ClassAttendance: Identifiable, Codable, Sendable {
    let id: String
    let classType: ClassType
    let date: Date
    let time: String
    let instructor: String

    nonisolated init(id: String, classType: ClassType, date: Date, time: String, instructor: String) {
        self.id = id
        self.classType = classType
        self.date = date
        self.time = time
        self.instructor = instructor
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let idInt = try? container.decode(Int.self, forKey: .id) {
            self.id = String(idInt)
        } else {
            self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        }

        self.classType = (try? container.decode(ClassType.self, forKey: .classType)) ?? .other
        self.date = (try? container.decode(Date.self, forKey: .date)) ?? Date()
        self.time = (try? container.decode(String.self, forKey: .time)) ?? ""
        self.instructor = (try? container.decode(String.self, forKey: .instructor)) ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case id, classType, date, time, instructor
    }
}

nonisolated struct UpcomingClass: Codable, Sendable {
    let classType: ClassType
    let date: Date
    let time: String
    let instructor: String
    /// The real class name from Mindbody (e.g. "Power 35"). Falls back to the
    /// mapped `classType` label when the source row doesn't include a name.
    let name: String?

    /// The best display title: the real Mindbody class name when available,
    /// then the mapped class type's label, and finally a neutral fallback so we
    /// never surface the raw "Other" placeholder when the source row has no name.
    var displayName: String {
        if let name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            return name
        }
        if classType != .other {
            return classType.rawValue
        }
        return "Upcoming Class"
    }

    nonisolated init(classType: ClassType, date: Date, time: String, instructor: String, name: String? = nil) {
        self.classType = classType
        self.date = date
        self.time = time
        self.instructor = instructor
        self.name = name
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.classType = (try? container.decode(ClassType.self, forKey: .classType)) ?? .other
        self.date = (try? container.decode(Date.self, forKey: .date)) ?? Date()
        self.time = (try? container.decode(String.self, forKey: .time)) ?? ""
        self.instructor = (try? container.decode(String.self, forKey: .instructor)) ?? ""
        self.name = try? container.decodeIfPresent(String.self, forKey: .name)
    }

    private enum CodingKeys: String, CodingKey {
        case classType, date, time, instructor, name
    }
}
