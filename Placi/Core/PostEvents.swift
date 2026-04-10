import Foundation
import Observation

/// Singleton broadcast channel for post creation events.
/// FeedViewModel observes this to auto-refresh without polling.
@Observable
final class PostEvents {
    static let shared = PostEvents()
    private init() {}

    var latestPost: Post?

    func postCreated(_ post: Post) {
        latestPost = post
    }
}
