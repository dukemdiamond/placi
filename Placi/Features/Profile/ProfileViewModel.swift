import Foundation
import Observation

@Observable
final class ProfileViewModel {
    var profile: Profile?
    var posts: [Post] = []
    var bookmarkedPlaces: [Place] = []
    var followerCount = 0
    var followingCount = 0
    var postCount = 0
    var isFollowing = false
    var isLoading = false
    var profileTab: ProfileTab = .been

    enum ProfileTab { case been, wantToGo, ranked }

    func load(userId: UUID, currentUserId: UUID?) async {
        isLoading = true
        defer { isLoading = false }

        async let p = ProfileService.fetchProfile(id: userId)
        async let userPosts = PostService.fetchUserPosts(userId: userId)
        async let followers = ProfileService.followerCount(userId: userId)
        async let following = ProfileService.followingCount(userId: userId)

        profile = try? await p
        posts = (try? await userPosts) ?? []
        postCount = posts.count
        followerCount = (try? await followers) ?? 0
        followingCount = (try? await following) ?? 0

        if let me = currentUserId, me != userId {
            isFollowing = (try? await ProfileService.isFollowing(followerId: me, followingId: userId)) ?? false
        }

        if let me = currentUserId, me == userId {
            bookmarkedPlaces = (try? await BookmarkService.fetchBookmarkedPlaces(userId: userId)) ?? []
        }
    }

    func toggleFollow(currentUserId: UUID?, targetId: UUID) async {
        guard let me = currentUserId else { return }
        do {
            if isFollowing {
                try await ProfileService.unfollow(followerId: me, followingId: targetId)
                followerCount = max(0, followerCount - 1)
            } else {
                try await ProfileService.follow(followerId: me, followingId: targetId)
                followerCount += 1
            }
            isFollowing.toggle()
        } catch {}
    }

    func reorder(postId: UUID, to position: Int) async {
        posts = RankingService.applyManualReorder(posts: &posts, movedPostId: postId, toPosition: position)
        try? await PostService.updatePlaciScores(posts)
    }
}
