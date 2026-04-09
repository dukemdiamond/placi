import Foundation
import Supabase

struct NotificationService {

    static func fetchNotifications(userId: UUID) async throws -> [AppNotification] {
        try await supabase
            .from("notifications")
            .select("*, profiles:actor_id(*)")
            .eq("recipient_id", value: userId)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value
    }

    static func markAllRead(userId: UUID) async throws {
        struct ReadUpdate: Encodable { let isRead: Bool; enum CodingKeys: String, CodingKey { case isRead = "is_read" } }
        try await supabase
            .from("notifications")
            .update(ReadUpdate(isRead: true))
            .eq("recipient_id", value: userId)
            .execute()
    }

    static func unreadCount(userId: UUID) async throws -> Int {
        let result = try await supabase
            .from("notifications")
            .select("*", head: true, count: .exact)
            .eq("recipient_id", value: userId)
            .eq("is_read", value: false)
            .execute()
        return result.count ?? 0
    }
}
