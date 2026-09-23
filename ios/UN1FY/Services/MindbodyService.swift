import AuthenticationServices
import Foundation
import UIKit

nonisolated enum MindbodyServiceError: LocalizedError, Sendable {
    case missingConfiguration
    case invalidConfiguration
    case invalidCallback
    case missingAuthorizationCode
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Mindbody configuration is missing."
        case .invalidConfiguration:
            return "Mindbody configuration is invalid."
        case .invalidCallback:
            return "Mindbody returned an invalid callback."
        case .missingAuthorizationCode:
            return "Mindbody did not return an authorization code."
        case .invalidResponse:
            return "Mindbody returned an invalid response."
        }
    }
}

@MainActor
final class MindbodyService: NSObject {
    private let session: URLSession
    private let callbackScheme: String = "un1fy"
    private let redirectURI: String = "un1fy://oauth/callback"
    private var authenticationSession: ASWebAuthenticationSession?

    private let startEndpoint = "https://gzxphxqjjdickalcilrq.supabase.co/functions/v1/auth-mindbody-start"
    private let exchangeEndpoint = "https://gzxphxqjjdickalcilrq.supabase.co/functions/v1/auth-mindbody-exchange"
    private let syncEndpoint = "https://gzxphxqjjdickalcilrq.supabase.co/functions/v1/auth-mindbody-sync"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func connect() async throws -> MindbodyAuthExchangeResponse {
        let startURL = try makeStartURL()
        let callbackURL = try await authenticate(startURL: startURL)
        let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
        let code = components?.queryItems?.first(where: { $0.name == "code" })?.value
        let state = components?.queryItems?.first(where: { $0.name == "state" })?.value

        guard let code, !code.isEmpty else {
            throw MindbodyServiceError.missingAuthorizationCode
        }

        let payload = MindbodyAuthExchangeRequest(
            code: code,
            state: state,
            redirectURI: redirectURI
        )

        var request = URLRequest(url: try makeExchangeURL())
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
            print("[UN1FY] Exchange failed with status \(statusCode): \(bodyString)")
            throw MindbodyServiceError.invalidResponse
        }

        let rawJSON = String(data: data, encoding: .utf8) ?? "<unable to decode>"
        print("[UN1FY] Exchange raw response: \(rawJSON)")

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = FlexibleDateDecoder.decodingStrategy()
        do {
            let decoded = try decoder.decode(MindbodyAuthExchangeResponse.self, from: data)
            print("[UN1FY] Decoded member firstName: \(decoded.member?.firstName ?? "nil"), lastName: \(decoded.member?.lastName ?? "nil")")
            return decoded
        } catch {
            print("[UN1FY] Decoding exchange response failed: \(error)")
            throw error
        }
    }

    private func makeStartURL() throws -> URL {
        guard var components = URLComponents(string: startEndpoint) else {
            throw MindbodyServiceError.invalidConfiguration
        }

        components.queryItems = [
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]

        guard let url = components.url else {
            throw MindbodyServiceError.invalidConfiguration
        }

        return url
    }

    func sync(accessToken: String, refreshToken: String?, clientId: Int?) async throws -> MindbodySyncResponse {
        let payload = MindbodySyncRequest(
            accessToken: accessToken,
            refreshToken: refreshToken,
            clientId: clientId,
            timezoneOffsetSeconds: TimeZone.current.secondsFromGMT()
        )

        var request = URLRequest(url: try makeSyncURL())
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw MindbodyServiceError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = FlexibleDateDecoder.decodingStrategy()
        do {
            return try decoder.decode(MindbodySyncResponse.self, from: data)
        } catch {
            print("[UN1FY] Decoding sync response failed: \(error)")
            throw error
        }
    }

    private func makeExchangeURL() throws -> URL {
        guard let url = URL(string: exchangeEndpoint) else {
            throw MindbodyServiceError.invalidConfiguration
        }
        return url
    }

    private func makeSyncURL() throws -> URL {
        guard let url = URL(string: syncEndpoint) else {
            throw MindbodyServiceError.invalidConfiguration
        }
        return url
    }

    private func authenticate(startURL: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            authenticationSession = ASWebAuthenticationSession(url: startURL, callbackURLScheme: callbackScheme) { [weak self] callbackURL, error in
                defer {
                    self?.authenticationSession = nil
                }

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL else {
                    continuation.resume(throwing: MindbodyServiceError.invalidCallback)
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            authenticationSession?.prefersEphemeralWebBrowserSession = true
            authenticationSession?.presentationContextProvider = MindbodyPresentationContextProvider.shared

            guard authenticationSession?.start() == true else {
                authenticationSession = nil
                continuation.resume(throwing: MindbodyServiceError.invalidConfiguration)
                return
            }
        }
    }
}
