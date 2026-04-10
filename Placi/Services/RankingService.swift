import Foundation

/// Placi Score: 1.0–10.0 with one decimal place.
///
/// Tiers (sentiment-based):
///   liked    → 7.0–10.0
///   okay     → 4.0–6.9
///   disliked → 1.0–3.9
///
/// Within each tier posts are ranked relative to each other (pairwise via
/// rank_position order). Drag-reorder on the Ranked tab is the pairwise signal.
struct RankingService {

    static func recompute(posts: inout [Post]) -> [Post] {
        guard !posts.isEmpty else { return posts }

        var liked    = posts.filter { $0.sentiment == .liked }
                            .sorted { ($0.rankPosition ?? Int.max) < ($1.rankPosition ?? Int.max) }
        var okay     = posts.filter { $0.sentiment == .okay }
                            .sorted { ($0.rankPosition ?? Int.max) < ($1.rankPosition ?? Int.max) }
        var disliked = posts.filter { $0.sentiment == .disliked }
                            .sorted { ($0.rankPosition ?? Int.max) < ($1.rankPosition ?? Int.max) }

        scoreWithinTier(&liked,    range: 7.0...10.0)
        scoreWithinTier(&okay,     range: 4.0...6.9)
        scoreWithinTier(&disliked, range: 1.0...3.9)

        var all = liked + okay + disliked
        for i in all.indices { all[i].rankPosition = i + 1 }
        posts = all
        return posts
    }

    static func applyManualReorder(posts: inout [Post], movedPostId: UUID, toPosition: Int) -> [Post] {
        guard let idx = posts.firstIndex(where: { $0.id == movedPostId }) else { return posts }
        var reordered = posts
        let moved = reordered.remove(at: idx)
        reordered.insert(moved, at: max(0, min(toPosition - 1, reordered.count)))
        for i in reordered.indices { reordered[i].rankPosition = i + 1 }
        posts = reordered
        return recompute(posts: &posts)
    }

    /// Live preview: what score would a new place with `sentiment` receive?
    static func previewScore(existingPosts: [Post], sentiment: PlaceSentiment) -> Double {
        let inTier = existingPosts.filter { $0.sentiment == sentiment }
        let range = sentiment.tierRange
        if inTier.isEmpty { return range.upperBound }
        // New place slots to top of its tier → near the upper bound
        let n = Double(inTier.count + 1)
        let score = range.upperBound - (0.0 / max(1, n - 1)) * (range.upperBound - range.lowerBound)
        return round(score * 10) / 10
    }

    private static func scoreWithinTier(_ tier: inout [Post], range: ClosedRange<Double>) {
        let n = tier.count
        guard n > 0 else { return }
        for i in tier.indices {
            let score: Double = n == 1
                ? range.upperBound
                : range.upperBound - (Double(i) / Double(n - 1)) * (range.upperBound - range.lowerBound)
            tier[i].placiScore = round(score * 10) / 10
        }
    }
}
