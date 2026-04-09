import Foundation

struct AppNotification: Codable, Identifiable, Hashable {
    let id: UUID
    var recipientId: UUID
    var actorId: UUID
    var type: NotificationType
    var postId: UUID?
    var isRead: Bool
    let createdAt: Date

    var actor: Profile?

    enum NotificationType: String, Codable {
        case like, comment, follow, share
    }

    enum CodingKeys: String, CodingKey {
        case id
        case recipientId = "recipient_id"
        case actorId = "actor_id"
        case type
        case postId = "post_id"
        case isRead = "is_read"
        case createdAt = "created_at"
        case actor = "profiles"
    }

    static func == (lhs: AppNotification, rhs: AppNotification) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        recipientId = try c.decode(UUID.self, forKey: .recipientId)
        actorId = try c.decode(UUID.self, forKey: .actorId)
        type = try c.decode(NotificationType.self, forKey: .type)
        postId = try c.decodeIfPresent(UUID.self, forKey: .postId)
        isRead = try c.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        actor = try c.decodeIfPresent(Profile.self, forKey: .actor)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(recipientId, forKey: .recipientId)
        try c.encode(actorId, forKey: .actorId)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(postId, forKey: .postId)
        try c.encode(isRead, forKey: .isRead)
        try c.encode(createdAt, forKey: .createdAt)
    }
}
