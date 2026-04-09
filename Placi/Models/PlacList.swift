import Foundation

struct PlacList: Codable, Identifiable, Hashable {
    let id: UUID
    var userId: UUID
    var name: String
    var isPublic: Bool
    let createdAt: Date
    var items: [PlacListItem]

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case isPublic = "is_public"
        case createdAt = "created_at"
        case items = "list_items"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        userId = try c.decode(UUID.self, forKey: .userId)
        name = try c.decode(String.self, forKey: .name)
        isPublic = try c.decodeIfPresent(Bool.self, forKey: .isPublic) ?? true
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        items = try c.decodeIfPresent([PlacListItem].self, forKey: .items) ?? []
    }
}

struct PlacListItem: Codable, Hashable {
    var listId: UUID
    var postId: UUID
    var displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case listId = "list_id"
        case postId = "post_id"
        case displayOrder = "display_order"
    }
}
