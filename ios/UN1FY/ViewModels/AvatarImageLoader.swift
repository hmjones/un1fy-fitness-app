import SwiftUI

/// Shared in-memory cache for avatar images. Each URL downloads exactly once
/// (deduped across all avatars on screen) and the decoded image is pushed to
/// every avatar showing it via observation. Replaces per-view `AsyncImage`,
/// which silently fails without retry when several instances request the same
/// URL simultaneously.
@Observable
@MainActor
final class AvatarImageLoader {
    static let shared = AvatarImageLoader()

    private(set) var images: [URL: UIImage] = [:]
    private var inFlight: Set<URL> = []

    private init() {}

    /// The cached image for a URL, or nil while it hasn't loaded yet.
    func image(for url: URL?) -> UIImage? {
        guard let url else { return nil }
        return images[url]
    }

    /// Puts a locally-known image straight into the cache (e.g. right after
    /// the member uploads a new photo) so it shows instantly everywhere.
    func seed(_ image: UIImage, for url: URL) {
        images[url] = image
    }

    /// Downloads the image once; concurrent callers for the same URL are
    /// deduped. A failed attempt clears the in-flight marker so the next
    /// appearance retries.
    func load(_ url: URL) async {
        guard images[url] == nil, !inFlight.contains(url) else { return }
        inFlight.insert(url)
        defer { inFlight.remove(url) }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                print("[UN1FY] Avatar image load failed (status) for \(url.lastPathComponent)")
                return
            }
            guard let image = UIImage(data: data) else {
                print("[UN1FY] Avatar image decode failed for \(url.lastPathComponent)")
                return
            }
            images[url] = image
        } catch {
            print("[UN1FY] Avatar image load failed for \(url.lastPathComponent): \(error)")
        }
    }
}
