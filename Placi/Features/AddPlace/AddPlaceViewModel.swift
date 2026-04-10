import Foundation
import Observation
import UIKit
import Supabase

@Observable
final class AddPlaceViewModel {
    var selectedPlace: Place?
    var isSubmitting = false
    var errorMessage: String?

    func submit(
        place: Place,
        title: String,
        notes: String,
        photos: [UIImage],
        sentiment: PlaceSentiment,
        isDraft: Bool,
        userId: UUID
    ) async throws -> Post {
        isSubmitting = true
        defer { isSubmitting = false }

        // 1. Upsert the canonical place
        let placeId = try await upsertPlace(place)

        // 2. Load existing posts for ranking
        var existingPosts = try await PostService.fetchUserPosts(userId: userId)

        // 3. Compute preview score
        let previewScore = RankingService.previewScore(existingPosts: existingPosts, sentiment: sentiment)

        // 4. Insert post
        let payload = PostService.CreatePostPayload(
            userId: userId,
            placeId: placeId,
            title: title,
            notes: notes.isEmpty ? nil : notes,
            baseRating: sentiment.baseRating,
            placiScore: previewScore,
            rankPosition: nil,
            isDraft: isDraft,
            sentiment: sentiment
        )
        var newPost = try await PostService.createPost(payload)

        // 5. Upload photos
        var photoPayloads: [PostService.PhotoPayload] = []
        for (i, image) in photos.enumerated() {
            let path = try await ImageService.uploadPostPhoto(image: image, postId: newPost.id, order: i)
            photoPayloads.append(PostService.PhotoPayload(postId: newPost.id, storagePath: path, displayOrder: i))
        }
        if !photoPayloads.isEmpty {
            try await PostService.insertPostPhotos(photoPayloads)
        }

        // 6. Recompute rankings for all user posts
        existingPosts.append(newPost)
        var allPosts = existingPosts
        allPosts = RankingService.recompute(posts: &allPosts)
        try await PostService.updatePlaciScores(allPosts)
        newPost.placiScore = allPosts.first(where: { $0.id == newPost.id })?.placiScore ?? previewScore

        return newPost
    }

    private func upsertPlace(_ place: Place) async throws -> UUID {
        struct PlacePayload: Encodable {
            let name: String; let address: String?
            let latitude: Double; let longitude: Double
            let category: String?; let mapkitId: String?
            enum CodingKeys: String, CodingKey {
                case name, address, latitude, longitude, category
                case mapkitId = "mapkit_id"
            }
        }
        let payload = PlacePayload(name: place.name, address: place.address,
                                   latitude: place.latitude, longitude: place.longitude,
                                   category: place.category, mapkitId: place.mapkitId)
        let inserted: Place = try await supabase
            .from("places").insert(payload).select().single().execute().value
        return inserted.id
    }
}
