import Foundation
import Security

nonisolated enum KeychainService: Sendable {
    private static let service = "com.un1fy.mindbody"

    private enum Key: String {
        case accessToken = "mindbody_access_token"
        case refreshToken = "mindbody_refresh_token"
        case lastSyncDate = "mindbody_last_sync"
        case connectionState = "mindbody_connected"
        case clientId = "mindbody_client_id"
        case firstName = "mindbody_first_name"
        case lastName = "mindbody_last_name"
    }

    static var accessToken: String? {
        get { read(key: .accessToken) }
        set { save(key: .accessToken, value: newValue) }
    }

    static var refreshToken: String? {
        get { read(key: .refreshToken) }
        set { save(key: .refreshToken, value: newValue) }
    }

    static var isConnected: Bool {
        get { read(key: .connectionState) == "true" }
        set { save(key: .connectionState, value: newValue ? "true" : nil) }
    }

    /// The member's resolved Mindbody client id. Persisting it lets the app
    /// restore the connection and re-fetch visits on relaunch without forcing
    /// the OAuth login again.
    static var clientId: Int? {
        get {
            guard let string = read(key: .clientId) else { return nil }
            return Int(string)
        }
        set {
            if let value = newValue {
                save(key: .clientId, value: String(value))
            } else {
                save(key: .clientId, value: nil)
            }
        }
    }

    static var firstName: String? {
        get { read(key: .firstName) }
        set { save(key: .firstName, value: newValue) }
    }

    static var lastName: String? {
        get { read(key: .lastName) }
        set { save(key: .lastName, value: newValue) }
    }

    static var lastSyncDate: Date? {
        get {
            guard let string = read(key: .lastSyncDate),
                  let interval = TimeInterval(string) else { return nil }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            if let date = newValue {
                save(key: .lastSyncDate, value: String(date.timeIntervalSince1970))
            } else {
                save(key: .lastSyncDate, value: nil)
            }
        }
    }

    static func clearAll() {
        accessToken = nil
        refreshToken = nil
        isConnected = false
        lastSyncDate = nil
        clientId = nil
        firstName = nil
        lastName = nil
    }

    private static func save(key: Key, value: String?) {
        let account = key.rawValue
        delete(key: key)

        guard let value, let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    private static func read(key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }

        return string
    }

    private static func delete(key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        SecItemDelete(query as CFDictionary)
    }
}
