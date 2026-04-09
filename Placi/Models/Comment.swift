import Foundation

struct Comment: Codable, Identifiable, Hashable {
    let id: UUID
    var userId: UUID
    var postId: UUID
    var parentId: UUID?
    var body: String
    let createdAt: Date

    var profile: Profile?
    var replies: [Comment]

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postId = "post_id"
        case parentId = "parent_id"
        case body
        case createdAt = "created_at"
        case profile = "profiles"
        case replies
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        userId = try c.decode(UUID.self, forKey: .userId)
        postId = try c.decode(UUID.self, forKey: .postId)
        parentId = try c.decodeIfPresent(UUID.self, forKey: .parentId)
        body = try c.decode(String.self, forKey: .body)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        profile = try c.decodeIfPresent(Profile.self, forKey: .profile)
        replies = try c.decodeIfPresent([Comment].self, forKey: .replies) ?? []
    }

    static func == (lhs: Comment, rhs: Comment) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(postId, forKey: .postId)
        try c.encodeIfPresent(parentId, forKey: .parentId)
        try c.encode(body, forKey: .body)
        try c.encode(createdAt, forKey: .createdAt)
    }
}
