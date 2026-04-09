import Foundation

struct Follow: Codable, Hashable {
    var followerId: UUID
    var followingId: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case followerId = "follower_id"
        case followingId = "following_id"
        case createdAt = "created_at"
    }
}
