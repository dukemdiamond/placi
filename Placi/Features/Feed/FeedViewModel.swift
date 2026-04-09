import Foundation
import Observation

@Observable
final class FeedViewModel {
    var posts: [Post] = []
    var isLoading = false
    private var currentPage = 0
    private let pageSize = 20
    private var hasMore = true
    private var userId: UUID?

    func loadInitial(userId: UUID) async {
        self.userId = userId
        guard !isLoading else { return }
        currentPage = 0
        hasMore = true
        posts = []
        await load()
    }

    func loadMore() async {
        guard !isLoading, hasMore else { return }
        await load()
    }

    func refresh() async {
        guard let userId else { return }
        await loadInitial(userId: userId)
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
        } catch {
            // TODO: surface error to UI
        }
    }
}
