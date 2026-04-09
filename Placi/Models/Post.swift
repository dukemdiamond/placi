import Foundation

struct Post: Codable, Identifiable, Hashable {
    let id: UUID
    var userId: UUID
    var placeId: UUID
    var title: String
    var notes: String?
    var baseRating: Int          // 1–10
    var placiScore: Double       // 0–100
    var rankPosition: Int?
    var isDraft: Bool
    let createdAt: Date
    var updatedAt: Date

    // Joined fields (not always present)
    var place: Place?
    var profile: Profile?
    var photos: [PostPhoto]
    var likeCount: Int
    var commentCount: Int
    var isLikedByCurrentUser: Bool

    // Transient — used during ranking computation
    var normalisedRating: Double = 0
    var weightedScore: Double = 0

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case placeId = "place_id"
        case title, notes
        case baseRating = "base_rating"
        case placiScore = "placi_score"
        case rankPosition = "rank_position"
        case isDraft = "is_draft"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case place, profile = "profiles", photos = "post_photos"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case isLikedByCurrentUser = "is_liked_by_current_user"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        userId = try c.decode(UUID.self, forKey: .userId)
        placeId = try c.decode(UUID.self, forKey: .placeId)
        title = try c.decode(String.self, forKey: .title)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        baseRating = try c.decode(Int.self, forKey: .baseRating)
        placiScore = try c.decodeIfPresent(Double.self, forKey: .placiScore) ?? 0
        rankPosition = try c.decodeIfPresent(Int.self, forKey: .rankPosition)
        isDraft = try c.decodeIfPresent(Bool.self, forKey: .isDraft) ?? false
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        place = try c.decodeIfPresent(Place.self, forKey: .place)
        profile = try c.decodeIfPresent(Profile.self, forKey: .profile)
        photos = try c.decodeIfPresent([PostPhoto].self, forKey: .photos) ?? []
        likeCount = try c.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        commentCount = try c.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        isLikedByCurrentUser = try c.decodeIfPresent(Bool.self, forKey: .isLikedByCurrentUser) ?? false
    }

    static func == (lhs: Post, rhs: Post) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(placeId, forKey: .placeId)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(notes, forKey: .notes)
        try c.encode(baseRating, forKey: .baseRating)
        try c.encode(placiScore, forKey: .placiScore)
        try c.encodeIfPresent(rankPosition, forKey: .rankPosition)
        try c.encode(isDraft, forKey: .isDraft)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }
}

struct PostPhoto: Codable, Identifiable, Hashable {
    let id: UUID
    var postId: UUID
    var storagePath: String
    var displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case storagePath = "storage_path"
        case displayOrder = "display_order"
    }
}
