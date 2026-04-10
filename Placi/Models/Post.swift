import Foundation

enum PlaceSentiment: String, Codable, CaseIterable {
    case liked    = "liked"
    case okay     = "okay"
    case disliked = "disliked"

    var label: String {
        switch self {
        case .liked:    return "I liked it!"
        case .okay:     return "It was okay"
        case .disliked: return "I didn't like it"
        }
    }

    var emoji: String {
        switch self {
        case .liked:    return "😊"
        case .okay:     return "😐"
        case .disliked: return "😕"
        }
    }

    /// Base rating integer stored in DB for backward compat
    var baseRating: Int {
        switch self {
        case .liked:    return 8
        case .okay:     return 5
        case .disliked: return 2
        }
    }

    /// Score tier range this sentiment belongs to
    var tierRange: ClosedRange<Double> {
        switch self {
        case .liked:    return 7.0...10.0
        case .okay:     return 4.0...6.9
        case .disliked: return 1.0...3.9
        }
    }
}

struct Post: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var placeId: UUID
    var title: String
    var notes: String?
    var baseRating: Int
    var placiScore: Double      // 1.0–10.0, one decimal
    var rankPosition: Int?
    var isDraft: Bool
    var sentiment: PlaceSentiment
    let createdAt: Date
    var updatedAt: Date

    // Joined fields
    var place: Place?
    var profile: Profile?
    var photos: [PostPhoto]
    var likeCount: Int
    var commentCount: Int
    var isLikedByCurrentUser: Bool

    // Transient — used during ranking
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
        case sentiment
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case place = "places"
        case profile = "profiles"
        case photos = "post_photos"
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
        baseRating = try c.decodeIfPresent(Int.self, forKey: .baseRating) ?? 5
        placiScore = try c.decodeIfPresent(Double.self, forKey: .placiScore) ?? 5.0
        rankPosition = try c.decodeIfPresent(Int.self, forKey: .rankPosition)
        isDraft = try c.decodeIfPresent(Bool.self, forKey: .isDraft) ?? false
        sentiment = try c.decodeIfPresent(PlaceSentiment.self, forKey: .sentiment) ?? .liked
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        place = try c.decodeIfPresent(Place.self, forKey: .place)
        profile = try c.decodeIfPresent(Profile.self, forKey: .profile)
        photos = try c.decodeIfPresent([PostPhoto].self, forKey: .photos) ?? []
        likeCount = try c.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        commentCount = try c.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        isLikedByCurrentUser = try c.decodeIfPresent(Bool.self, forKey: .isLikedByCurrentUser) ?? false
    }

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
        try c.encode(sentiment, forKey: .sentiment)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }

    static func == (lhs: Post, rhs: Post) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension Post: Hashable, Equatable {}

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
