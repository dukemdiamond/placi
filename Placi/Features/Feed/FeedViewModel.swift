import Foundation
import Observation

@Observable
final class FeedViewModel {
    var posts: [Post] = []
    var isLoading = false
    private var currentPage = 0
    private let pageSize = 20
    private var hasMore = true

    func loadInitial() async {
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
        await loadInitial()
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let from = currentPage * pageSize
            let to = from + pageSize - 1
            let newPosts = try await PostService.fetchFeedPosts(range: from...to)
            posts += newPosts
            hasMore = newPosts.count == pageSize
            currentPage += 1
        } catch {
            // TODO: surface error to UI
        }
    }
}
