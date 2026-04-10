import Foundation

/// Placi Score: 1.0–10.0 with one decimal place.
///
/// Algorithm:
/// 1. Posts are grouped into sentiment tiers:
///    - liked    → 7.0–10.0
///    - okay     → 4.0–6.9
///    - disliked → 1.0–3.9
/// 2. Within each tier, posts are ranked by their current rank_position
///    (or weighted score if no position exists). This is the "pairwise" signal —
///    manual drag-reorder moves posts within/between tiers.
/// 3. Score is linearly interpolated across the tier range:
///    rank 1 in tier → tier max, last in tier → tier min.
/// 4. Rounded to one decimal place.
///
/// The net effect: sentiment determines the bracket; relative position
/// within that bracket determines the precise score. Two places with the
/// same sentiment are compared against each other ("pairwise") via rank order.
struct RankingService {

    // MARK: - Recompute all posts

    static func recompute(posts: inout [Post]) -> [Post] {
        guard !posts.isEmpty else { return posts }

        // Split into tiers, preserving existing rank_position order within each
        var liked    = posts.filter { $0.sentiment == .liked }
                            .sorted { ($0.rankPosition ?? Int.max) < ($1.rankPosition ?? Int.max) }
        var okay     = posts.filter { $0.sentiment == .okay }
                            .sorted { ($0.rankPosition ?? Int.max) < ($1.rankPosition ?? Int.max) }
        var disliked = posts.filter { $0.sentiment == .disliked }
                            .sorted { ($0.rankPosition ?? Int.max) < ($1.rankPosition ?? Int.max) }

        // Score each tier
        scoreWithinTier(&liked,    range: 7.0...10.0)
        scoreWithinTier(&okay,     range: 4.0...6.9)
        scoreWithinTier(&disliked, range: 1.0...3.9)

        // Reassemble: liked first (best), then okay, then disliked
        var all = liked + okay + disliked
        for i in all.indices {
            all[i].rankPosition = i + 1
        }

        posts = all
        return posts
    }

    // MARK: - Manual reorder (pairwise drag signal)

    static func applyManualReorder(posts: inout [Post], movedPostId: UUID, toPosition: Int) -> [Post] {
        guard let idx = posts.firstIndex(where: { $0.id == movedPostId }) else { return posts }
        var reordered = posts
        let moved = reordered.remove(at: idx)
        let insertAt = min(toPosition - 1, reordered.count)
        reordered.insert(moved, at: max(0, insertAt))
        for i in reordered.indices { reordered[i].rankPosition = i + 1 }
        posts = reordered
        return recompute(posts: &posts)
    }

    // MARK: - Live preview score for PostFormView

    /// Returns what score a new place with `sentiment` would receive
    /// if added to `existingPosts`. Used for the live preview while the user fills out the form.
    static func previewScore(existingPosts: [Post], sentiment: PlaceSentiment) -> Double {
        let inTier = existingPosts.filter { $0.sentiment == sentiment }
        let range = sentiment.tierRange
        if inTier.isEmpty {
            // First in its tier — gets the top of the range
            return range.upperBound
        }
        // New place would slot in at position 1 within its tier (best of the tier so far),
        // pushing existing ones down. This gives an optimistic preview.
        let n = Double(inTier.count + 1)
        // Position 1 of n → score near the top
        let score = range.upperBound - (0.0 / (n - 1)) * (range.upperBound - range.lowerBound)
        return round(score * 10) / 10
    }

    // MARK: - Private helpers

    private static func scoreWithinTier(_ tier: inout [Post], range: ClosedRange<Double>) {
        let n = tier.count
        guard n > 0 else { return }
        for i in tier.indices {
            let score: Double
            if n == 1 {
                // Only one post in this tier — sits at the top of the range
                score = range.upperBound
            } else {
                // Linearly interpolate: rank 0 (best) → upper bound, rank n-1 → lower bound
                let position = Double(i) / Double(n - 1)
                score = range.upperBound - position * (range.upperBound - range.lowerBound)
            }
            tier[i].placiScore = round(score * 10) / 10
        }
    }
}
