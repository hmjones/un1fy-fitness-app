import Foundation

nonisolated enum FlexibleDateDecoder {
    static func decodingStrategy() -> JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()

            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            }

            if let timestamp = try? container.decode(Int.self) {
                return Date(timeIntervalSince1970: Double(timestamp))
            }

            let dateString = try container.decode(String.self)
            let trimmed = dateString.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty {
                return Date()
            }

            for formatter in allFormatters {
                if let date = formatter.date(from: trimmed) {
                    return date
                }
            }

            if let date = iso8601WithFractionalSeconds.date(from: trimmed) {
                return date
            }
            if let date = iso8601Standard.date(from: trimmed) {
                return date
            }

            print("[UN1FY] FlexibleDateDecoder: Cannot decode date from: \(trimmed)")
            return Date()
        }
    }

    private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601Standard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let allFormatters: [DateFormatter] = {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "MM-dd-yyyy",
            "M/d/yyyy h:mm:ss a",
            "M/d/yyyy h:mm a",
            "MM/dd/yyyy HH:mm:ss",
        ]
        return formats.map { format in
            let f = DateFormatter()
            f.dateFormat = format
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone(secondsFromGMT: 0)
            return f
        }
    }()
}
