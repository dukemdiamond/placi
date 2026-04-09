import Foundation
import Supabase

struct PostService {

    // MARK: - Fetch

    static func fetchFeedPosts(range: ClosedRange<Int>) async throws -> [Post] {
        try await supabase
            .from("posts")
            .select("*, places(*), profiles(*), post_photos(*)")
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
            .order("rank_position", ascending: true)
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

    // MARK: - Update

    static func updatePlaciScores(_ posts: [Post]) async throws {
        for post in posts {
            struct ScoreUpdate: Encodable {
                let placiScore: Double
                let rankPosition: Int?
                enum CodingKeys: String, CodingKey {
                    case placiScore = "placi_score"
                    case rankPosition = "rank_position"
                }
            }
            let update = ScoreUpdate(placiScore: post.placiScore, rankPosition: post.rankPosition)
            try await supabase
                .from("posts")
                .update(update)
                .eq("id", value: post.id)
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
                case userId = "user_id"
                case postId = "post_id"
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
            .isFilter("parent_id", value: "null")
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    static func addComment(postId: UUID, userId: UUID, body: String, parentId: UUID? = nil) async throws -> Comment {
        struct CommentPayload: Encodable {
            let userId: UUID
            let postId: UUID
            let body: String
            let parentId: UUID?
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case postId = "post_id"
                case body
                case parentId = "parent_id"
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
}
