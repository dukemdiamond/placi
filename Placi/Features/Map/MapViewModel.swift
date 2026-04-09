import Foundation
import Observation
import CoreLocation
import Supabase

@Observable
final class MapViewModel {
    var posts: [Post] = []
    var filter: Filter = .mine
    var pendingCoordinate: CLLocationCoordinate2D?
    private var currentUserId: UUID?

    enum Filter { case mine, following }

    func loadPosts(userId: UUID) async {
        self.currentUserId = userId
        do {
            switch filter {
            case .mine:
                posts = try await PostService.fetchUserPosts(userId: userId)
            case .following:
                posts = try await PostService.fetchFeedPosts(userId: userId, range: 0...199)
            }
        } catch {
            // TODO: surface error
        }
    }
}
