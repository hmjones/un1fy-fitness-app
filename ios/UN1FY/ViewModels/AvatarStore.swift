import SwiftUI

/// Shared directory of member profile photos keyed by Mindbody client id.
/// Loaded once from the `member_profiles` table and consulted everywhere an
/// avatar renders (profile, home greeting, feed posts, comments, leaderboard).
/// Also owns the current member's upload / remove flow.
@Observable
@MainActor
final class AvatarStore {
    static let shared = AvatarStore()

    private(set) var photoUrls: [Int: String] = [:]
    private(set) var ownClientId: Int?
    var isUploading: Bool = false
    var errorMessage: String?

    private let service = SupabaseProfileService()
    private var hasLoaded: Bool = false

    private init() {}

    /// Sets the identity used for uploads. Called whenever the resolved
    /// Mindbody client id becomes available or is corrected.
    func configure(clientId: Int?) {
        if let clientId {
            ownClientId = clientId
        }
    }

    /// The photo URL for any member, or nil to fall back to initials.
    func url(for clientId: Int?) -> URL? {
        guard let clientId, let raw = photoUrls[clientId] else { return nil }
        return URL(string: raw)
    }

    var ownPhotoUrl: URL? {
        url(for: ownClientId)
    }

    var hasOwnPhoto: Bool {
        guard let ownClientId else { return false }
        return photoUrls[ownClientId] != nil
    }

    /// Loads the photo directory once; later refreshes happen via `refresh()`.
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
    }

    /// Re-fetches every member's photo URL from Supabase.
    func refresh() async {
        do {
            let records = try await service.fetchProfiles()
            var map: [Int: String] = [:]
            for record in records {
                if let photoUrl = record.photoUrl, !photoUrl.isEmpty {
                    map[record.clientId] = photoUrl
                }
            }
            photoUrls = map
            hasLoaded = true
        } catch {
            print("[UN1FY] Avatar directory refresh failed: \(error)")
        }
    }

    /// Crops, compresses, uploads the picked image, and saves its URL to the
    /// member's profile row. On failure the previous photo (or initials) stays.
    func setPhoto(imageData: Data, memberName: String) async {
        guard let clientId = ownClientId else {
            errorMessage = "Connect Mindbody first to set a profile photo."
            return
        }
        guard let prepared = preparedSquareJPEG(from: imageData) else {
            errorMessage = "That image couldn't be read. Try a different one."
            return
        }

        isUploading = true
        errorMessage = nil
        do {
            let url = try await service.uploadPhoto(data: prepared, clientId: clientId)
            try await service.upsertProfile(clientId: clientId, memberName: memberName, photoUrl: url)
            photoUrls[clientId] = url
            // Seed the image cache with the just-uploaded photo so it appears
            // instantly everywhere without a round-trip download.
            if let seedUrl = URL(string: url), let image = UIImage(data: prepared) {
                AvatarImageLoader.shared.seed(image, for: seedUrl)
            }
        } catch {
            print("[UN1FY] Avatar upload failed: \(error)")
            errorMessage = "Couldn't upload your photo. Please try again."
        }
        isUploading = false
    }

    /// Removes the member's photo so their initials show again everywhere.
    func removePhoto() async {
        guard let clientId = ownClientId, let previous = photoUrls[clientId] else { return }

        photoUrls[clientId] = nil
        errorMessage = nil
        do {
            try await service.clearPhoto(clientId: clientId)
        } catch {
            print("[UN1FY] Avatar removal failed: \(error)")
            photoUrls[clientId] = previous
            errorMessage = "Couldn't remove your photo. Please try again."
        }
    }

    // MARK: - Private

    /// Center-crops the image to a square and downsizes it to 512px so avatar
    /// uploads stay small and load fast in the feed.
    private func preparedSquareJPEG(from data: Data) -> Data? {
        guard let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else {
            return nil
        }
        let side = min(image.size.width, image.size.height)
        let scale = min(512 / side, 1)
        let outputSide = side * scale
        // Force a 1x renderer scale so 512pt really means 512px — the default
        // device scale (2–3x) tripled the pixel count and upload size.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: outputSide, height: outputSide), format: format)
        let cropped = renderer.image { _ in
            let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(
                x: (outputSide - drawSize.width) / 2,
                y: (outputSide - drawSize.height) / 2
            )
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }
        return cropped.jpegData(compressionQuality: 0.82)
    }
}
