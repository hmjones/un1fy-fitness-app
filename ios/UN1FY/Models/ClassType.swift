import Foundation

nonisolated enum ClassType: String, CaseIterable, Identifiable, Sendable {
    case power35 = "Power35"
    case sculpt45 = "Sculpt45"
    case runClub = "Run Club"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .power35: return "bolt.fill"
        case .sculpt45: return "figure.strengthtraining.traditional"
        case .runClub: return "figure.run"
        case .other: return "figure.mixed.cardio"
        }
    }

    var color: String {
        switch self {
        case .power35: return "power"
        case .sculpt45: return "sculpt"
        case .runClub: return "run"
        case .other: return "power"
        }
    }
}

extension ClassType: Codable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = ClassType(rawValue: rawValue) ?? .other
    }
}
