import Foundation

/// A member's shared profile record from the Supabase `member_profiles` table.
/// Currently carries the cloud-stored profile photo shown across the app.
nonisolated struct MemberProfileRecord: Decodable, Sendable {
    let clientId: Int
    let memberName: String?
    let photoUrl: String?

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case memberName = "member_name"
        case photoUrl = "photo_url"
    }
}
