import Foundation
import Supabase
import PostgREST

struct PostService {

    // MARK: - Fetch

    /// Home feed — posts from people the current user follows, newest first
    static func fetchFeedPosts(userId: UUID, range: ClosedRange<Int>) async throws -> [Post] {
        let rows: [FollowingRow] = try await supabase
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: userId)
            .execute()
            .value
        let followingIds = rows.map(\.followingId)
        guard !followingIds.isEmpty else { return [] }

        return try await supabase
            .from("posts")
            .select("*, places(*), profiles(*), post_photos(*)")
            .in("user_id", values: followingIds)
            .eq("is_draft", value: false)
            .order("created_at", ascending: false)
            .range(from: range.lowerBound, to: range.upperBound)
            .execute()
            .value
    }

    static func fetchUserPosts(userId: UUID) async throws -> [Post] {
        try await supabase
            .from("posts")
            .select("*, places(*), profiles(*), post_photos(*)")
            .eq("user_id", value: userId)
            .eq("is_draft", value: false)
            .order("rank_position", ascending: true, nullsFirst: false)
            .execute()
            .value
    }

    static func fetchPost(id: UUID) async throws -> Post {
        try await supabase
            .from("posts")
            .select("*, places(*), profiles(*), post_photos(*)")
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    static func fetchPostsAtPlace(placeId: UUID) async throws -> [Post] {
        try await supabase
            .from("posts")
            .select("*, places(*), profiles(*), post_photos(*)")
            .eq("place_id", value: placeId)
            .eq("is_draft", value: false)
            .order("placi_score", ascending: false)
            .execute()
            .value
    }

    // MARK: - Create

    struct CreatePostPayload: Encodable {
        let userId: UUID
        let placeId: UUID
        let title: String
        let notes: String?
        let baseRating: Int
        let placiScore: Double
        let rankPosition: Int?
        let isDraft: Bool

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case placeId = "place_id"
            case title, notes
            case baseRating = "base_rating"
            case placiScore = "placi_score"
            case rankPosition = "rank_position"
            case isDraft = "is_draft"
        }
    }

    static func createPost(_ payload: CreatePostPayload) async throws -> Post {
        try await supabase
            .from("posts")
            .insert(payload)
            .select("*, places(*), profiles(*), post_photos(*)")
            .single()
            .execute()
            .value
    }

    // MARK: - Photos

    struct PhotoPayload: Encodable {
        let postId: UUID
        let storagePath: String
        let displayOrder: Int
        enum CodingKeys: String, CodingKey {
            case postId = "post_id"
            case storagePath = "storage_path"
            case displayOrder = "display_order"
        }
    }

    static func insertPostPhotos(_ photos: [PhotoPayload]) async throws {
        guard !photos.isEmpty else { return }
        try await supabase
            .from("post_photos")
            .insert(photos)
            .execute()
    }

    // MARK: - Update

    static func updatePlaciScores(_ posts: [Post]) async throws {
        struct ScoreUpdate: Encodable {
            let id: UUID
            let placiScore: Double
            let rankPosition: Int?
            enum CodingKeys: String, CodingKey {
                case id
                case placiScore = "placi_score"
                case rankPosition = "rank_position"
            }
        }
        let updates = posts.map { ScoreUpdate(id: $0.id, placiScore: $0.placiScore, rankPosition: $0.rankPosition) }
        for update in updates {
            try await supabase
                .from("posts")
                .update(update)
                .eq("id", value: update.id)
                .execute()
        }
    }

    static func deletePost(id: UUID) async throws {
        try await supabase
            .from("posts")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Likes

    static func likePost(postId: UUID, userId: UUID) async throws {
        struct LikePayload: Encodable {
            let userId: UUID
            let postId: UUID
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"; case postId = "post_id"
            }
        }
        try await supabase
            .from("likes")
            .insert(LikePayload(userId: userId, postId: postId))
            .execute()
    }

    static func unlikePost(postId: UUID, userId: UUID) async throws {
        try await supabase
            .from("likes")
            .delete()
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()
    }

    // MARK: - Comments

    static func fetchComments(postId: UUID) async throws -> [Comment] {
        try await supabase
            .from("comments")
            .select("*, profiles(*)")
            .eq("post_id", value: postId)
            .is("parent_id", value: AnyJSON.null)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    static func addComment(postId: UUID, userId: UUID, body: String, parentId: UUID? = nil) async throws -> Comment {
        struct CommentPayload: Encodable {
            let userId: UUID; let postId: UUID; let body: String; let parentId: UUID?
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"; case postId = "post_id"; case body; case parentId = "parent_id"
            }
        }
        return try await supabase
            .from("comments")
            .insert(CommentPayload(userId: userId, postId: postId, body: body, parentId: parentId))
            .select("*, profiles(*)")
            .single()
            .execute()
            .value
    }

    // MARK: - Shares

    static func sharePost(originalPostId: UUID, userId: UUID) async throws {
        struct SharePayload: Encodable {
            let userId: UUID; let originalPostId: UUID
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"; case originalPostId = "original_post_id"
            }
        }
        try await supabase
            .from("shares")
            .insert(SharePayload(userId: userId, originalPostId: originalPostId))
            .execute()
    }
}

// MARK: - Private helpers

private struct FollowingRow: Decodable {
    let followingId: String
    enum CodingKeys: String, CodingKey { case followingId = "following_id" }
}

