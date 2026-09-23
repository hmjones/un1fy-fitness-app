import AuthenticationServices
import UIKit

@MainActor
final class MindbodyPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = MindbodyPresentationContextProvider()

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
        }
    }
}
