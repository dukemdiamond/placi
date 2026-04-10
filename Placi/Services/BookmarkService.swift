import Foundation
import Supabase

struct BookmarkService {

    static func fetchBookmarkedPlaces(userId: UUID) async throws -> [Place] {
        struct BookmarkRow: Decodable {
            let places: Place
            enum CodingKeys: String, CodingKey { case places }
        }
        let rows: [BookmarkRow] = try await supabase
            .from("bookmarks")
            .select("places(*)")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map(\.places)
    }

    static func addBookmark(userId: UUID, placeId: UUID) async throws {
        struct Payload: Encodable {
            let userId: UUID; let placeId: UUID
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"; case placeId = "place_id"
            }
        }
        try await supabase
            .from("bookmarks")
            .insert(Payload(userId: userId, placeId: placeId))
            .execute()
    }

    static func removeBookmark(userId: UUID, placeId: UUID) async throws {
        try await supabase
            .from("bookmarks")
            .delete()
            .eq("user_id", value: userId)
            .eq("place_id", value: placeId)
            .execute()
    }

    static func isBookmarked(userId: UUID, placeId: UUID) async throws -> Bool {
        let result: [Place] = try await supabase
            .from("bookmarks")
            .select("places(*)")
            .eq("user_id", value: userId)
            .eq("place_id", value: placeId)
            .execute()
            .value
        return !result.isEmpty
    }
}
