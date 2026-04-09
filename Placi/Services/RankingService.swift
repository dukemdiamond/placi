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
    /// Simulates inserting a post with `draftRating` into the existing set and
    /// returns its percentile-based score (0–100).
    static func previewScore(existingPosts: [Post], draftRating: Int) -> Double {
        guard !existingPosts.isEmpty else {
            return 100  // first post always gets 100
        }
        let maxRating = Double(max(existingPosts.map(\.baseRating).max() ?? 10, draftRating))
        let draftNorm = Double(draftRating) / maxRating
        let allNorms = existingPosts.map { Double($0.baseRating) / maxRating } + [draftNorm]
        let sorted = allNorms.sorted(by: >)
        // firstIndex returns the first occurrence — fine for preview purposes
        let rank = (sorted.firstIndex(of: draftNorm) ?? 0) + 1
        let percentile = 1.0 - (Double(rank - 1) / Double(sorted.count))
        return (percentile * 100).rounded()
    }
}
