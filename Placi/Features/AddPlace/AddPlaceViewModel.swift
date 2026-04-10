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

        let placeId = try await upsertPlace(place)
        var existingPosts = try await PostService.fetchUserPosts(userId: userId)
        let previewScore = RankingService.previewScore(existingPosts: existingPosts, sentiment: sentiment)

        let payload = PostService.CreatePostPayload(
            userId: userId, placeId: placeId,
            title: title, notes: notes.isEmpty ? nil : notes,
            baseRating: sentiment.baseRating,
            placiScore: previewScore,
            rankPosition: nil, isDraft: isDraft,
            sentiment: sentiment
        )
        var newPost = try await PostService.createPost(payload)

        var photoPayloads: [PostService.PhotoPayload] = []
        for (i, image) in photos.enumerated() {
            let path = try await ImageService.uploadPostPhoto(image: image, postId: newPost.id, order: i)
            photoPayloads.append(.init(postId: newPost.id, storagePath: path, displayOrder: i))
        }
        if !photoPayloads.isEmpty { try await PostService.insertPostPhotos(photoPayloads) }

        existingPosts.append(newPost)
        var all = existingPosts
        all = RankingService.recompute(posts: &all)
        try await PostService.updatePlaciScores(all)
        newPost.placiScore = all.first(where: { $0.id == newPost.id })?.placiScore ?? previewScore
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
        let inserted: Place = try await supabase
            .from("places")
            .insert(PlacePayload(name: place.name, address: place.address,
                                 latitude: place.latitude, longitude: place.longitude,
                                 category: place.category, mapkitId: place.mapkitId))
            .select().single().execute().value
        return inserted.id
    }
}
