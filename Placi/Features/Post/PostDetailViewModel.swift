import Foundation
import Observation

@Observable
final class PostDetailViewModel {
    var post: Post?
    var comments: [Comment] = []
    var isLoading = false

    func load(postId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        async let p = PostService.fetchPost(id: postId)
        async let c = PostService.fetchComments(postId: postId)
        post = try? await p
        comments = (try? await c) ?? []
    }

    func toggleLike(userId: UUID?) async {
        guard let uid = userId, let postId = post?.id else { return }
        if post?.isLikedByCurrentUser == true {
            try? await PostService.unlikePost(postId: postId, userId: uid)
            post?.likeCount = max(0, (post?.likeCount ?? 1) - 1)
            post?.isLikedByCurrentUser = false
        } else {
            try? await PostService.likePost(postId: postId, userId: uid)
            post?.likeCount = (post?.likeCount ?? 0) + 1
            post?.isLikedByCurrentUser = true
        }
    }

    func addComment(body: String, userId: UUID?) async {
        guard let uid = userId, let postId = post?.id, !body.isEmpty else { return }
        if let comment = try? await PostService.addComment(postId: postId, userId: uid, body: body) {
            comments.append(comment)
            post?.commentCount = (post?.commentCount ?? 0) + 1
        }
    }

    func sharePost(userId: UUID?) async {
        guard let uid = userId, let postId = post?.id else { return }
        try? await PostService.sharePost(originalPostId: postId, userId: uid)
    }
}
