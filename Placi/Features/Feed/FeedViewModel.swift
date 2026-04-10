import Foundation
import Observation

@Observable
final class FeedViewModel {
    var posts: [Post] = []
    var suggestedUsers: [Profile] = []
    var isLoading = false
    private var currentPage = 0
    private let pageSize = 20
    private var hasMore = true
    private var userId: UUID?

    func loadInitial(userId: UUID) async {
        self.userId = userId
        currentPage = 0
        hasMore = true
        posts = []
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.load() }
            group.addTask { await self.loadSuggested(userId: userId) }
        }
    }

    func loadMore() async {
        guard !isLoading, hasMore else { return }
        await load()
    }

    func refresh() async {
        guard let userId else { return }
        await loadInitial(userId: userId)
    }

    func toggleLike(post: Post) async {
        guard let userId else { return }
        if post.isLikedByCurrentUser {
            try? await PostService.unlikePost(postId: post.id, userId: userId)
        } else {
            try? await PostService.likePost(postId: post.id, userId: userId)
        }
    }

    private func load() async {
        guard let userId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let from = currentPage * pageSize
            let to = from + pageSize - 1
            let newPosts = try await PostService.fetchFeedPosts(userId: userId, range: from...to)
            posts += newPosts
            hasMore = newPosts.count == pageSize
            currentPage += 1
        } catch {}
    }

    private func loadSuggested(userId: UUID) async {
        do {
            // Get IDs already followed
            let allProfiles: [Profile] = try await supabase
                .from("profiles")
                .select()
                .neq("id", value: userId)
                .limit(20)
                .execute()
                .value
            // Exclude self; keep up to 8 for the strip
            suggestedUsers = Array(allProfiles.prefix(8))
        } catch {}
    }
}
