import Foundation

struct Like: Codable, Hashable {
    var userId: UUID
    var postId: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case postId = "post_id"
        case createdAt = "created_at"
    }
}
