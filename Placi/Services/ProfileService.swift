import Foundation
import Supabase

struct ProfileService {

    static func fetchProfile(id: UUID) async throws -> Profile {
        try await supabase
            .from("profiles")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    static func fetchProfile(username: String) async throws -> Profile {
        try await supabase
            .from("profiles")
            .select()
            .eq("username", value: username)
            .single()
            .execute()
            .value
    }

    static func searchProfiles(query: String) async throws -> [Profile] {
        try await supabase
            .from("profiles")
            .select()
            .ilike("username", value: "%\(query)%")
            .limit(20)
            .execute()
            .value
    }

    struct CreateProfilePayload: Encodable {
        let id: UUID
        let username: String
        let displayName: String
        let bio: String?
        let avatarUrl: String?
        enum CodingKeys: String, CodingKey {
            case id, username
            case displayName = "display_name"
            case bio
            case avatarUrl = "avatar_url"
        }
    }

    static func createProfile(_ payload: CreateProfilePayload) async throws -> Profile {
        try await supabase
            .from("profiles")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    struct UpdateProfilePayload: Encodable {
        let displayName: String?
        let bio: String?
        let avatarUrl: String?
        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case bio
            case avatarUrl = "avatar_url"
        }
    }

    static func updateProfile(id: UUID, payload: UpdateProfilePayload) async throws -> Profile {
        try await supabase
            .from("profiles")
            .update(payload)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Follows

    static func follow(followerId: UUID, followingId: UUID) async throws {
        struct FollowPayload: Encodable {
            let followerId: UUID
            let followingId: UUID
            enum CodingKeys: String, CodingKey {
                case followerId = "follower_id"
                case followingId = "following_id"
            }
        }
        try await supabase
            .from("follows")
            .insert(FollowPayload(followerId: followerId, followingId: followingId))
            .execute()
    }

    static func unfollow(followerId: UUID, followingId: UUID) async throws {
        try await supabase
            .from("follows")
            .delete()
            .eq("follower_id", value: followerId)
            .eq("following_id", value: followingId)
            .execute()
    }

    static func isFollowing(followerId: UUID, followingId: UUID) async throws -> Bool {
        let result: [Follow] = try await supabase
            .from("follows")
            .select()
            .eq("follower_id", value: followerId)
            .eq("following_id", value: followingId)
            .execute()
            .value
        return !result.isEmpty
    }

    static func followerCount(userId: UUID) async throws -> Int {
        let result = try await supabase
            .from("follows")
            .select("*", head: true, count: .exact)
            .eq("following_id", value: userId)
            .execute()
        return result.count ?? 0
    }

    static func followingCount(userId: UUID) async throws -> Int {
        let result = try await supabase
            .from("follows")
            .select("*", head: true, count: .exact)
            .eq("follower_id", value: userId)
            .execute()
        return result.count ?? 0
    }
}
