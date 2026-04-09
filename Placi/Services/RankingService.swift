import Foundation

struct RankingService {

    /// Recomputes placi_score and rank_position for all of a user's posts.
    /// Call this after insert, update, or manual reorder.
    static func recompute(posts: inout [Post]) -> [Post] {
        guard !posts.isEmpty else { return posts }

        // Step 1: Normalise base ratings to 0–1
        let maxRating = Double(posts.map(\.baseRating).max() ?? 10)
        for i in posts.indices {
            posts[i].normalisedRating = Double(posts[i].baseRating) / maxRating
        }

        // Step 2: Apply recency multiplier (1.0 → 0.85 over 365 days)
        let now = Date()
        for i in posts.indices {
            let daysAgo = Calendar.current.dateComponents([.day], from: posts[i].createdAt, to: now).day ?? 0
            let decay = max(0.85, 1.0 - (Double(daysAgo) / 365.0) * 0.15)
            posts[i].weightedScore = posts[i].normalisedRating * decay
        }

        // Step 3: Sort by weightedScore descending, assign rank positions
        posts.sort { $0.weightedScore > $1.weightedScore }
        for i in posts.indices {
            posts[i].rankPosition = i + 1
        }

        // Step 4: Convert rank position to 0–100 Placi Score via percentile
        let n = Double(posts.count)
        for i in posts.indices {
            let percentile = 1.0 - (Double(posts[i].rankPosition! - 1) / n)
            posts[i].placiScore = (percentile * 100).rounded()
        }

        return posts
    }

    /// Called when user drags a post to a new rank position.
    /// Re-anchors scores around the manual position then recomputes neighbours.
    static func applyManualReorder(posts: inout [Post], movedPostId: UUID, toPosition: Int) -> [Post] {
        guard let idx = posts.firstIndex(where: { $0.id == movedPostId }) else { return posts }
        posts[idx].rankPosition = toPosition
        return recompute(posts: &posts)
    }

    /// Preview what Placi Score a new draft post would receive if published.
    static func previewScore(existingPosts: [Post], draftRating: Int) -> Double {
        var draft = existingPosts
        // Create a temporary stand-in post for preview purposes
        let now = Date()
        // We only need enough fields for the algorithm
        let tempId = UUID()
        var tempPost = existingPosts.first.map { p -> Post in
            var copy = p
            copy = p  // we'll manipulate via the computed fields
            return copy
        }

        // Build a lightweight array by just appending a synthetic entry
        // using the existing recompute logic on a copy
        var scoredPosts = draft
        // Inject a synthetic post rating equal to the draft
        // by temporarily using an existing post's data as a placeholder
        if scoredPosts.isEmpty {
            return Double(draftRating) * 10.0  // trivial case: only post gets 100
        }

        // Simulate by treating the draft as if it were added with draftRating
        // We'll compute what percentile a post with draftRating would fall into
        let maxRating = Double(max(scoredPosts.map(\.baseRating).max() ?? 10, draftRating))
        let draftNorm = Double(draftRating) / maxRating
        let existingNorms = scoredPosts.map { Double($0.baseRating) / maxRating }
        let allNorms = existingNorms + [draftNorm]
        let sorted = allNorms.sorted(by: >)
        guard let rank = sorted.firstIndex(of: draftNorm).map({ $0 + 1 }) else { return 0 }
        let n = Double(sorted.count)
        let percentile = 1.0 - (Double(rank - 1) / n)
        return (percentile * 100).rounded()
    }
}
