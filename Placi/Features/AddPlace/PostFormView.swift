import SwiftUI
import PhotosUI

struct PostFormView: View {
    let place: Place
    @Bindable var viewModel: AddPlaceViewModel

    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var rating = 7
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var photos: [UIImage] = []
    @State private var previewScore: Double = 0
    @State private var existingPosts: [Post] = []

    var body: some View {
        Form {
            Section("Place") {
                Text(place.name).font(.headline)
                if let address = place.address {
                    Text(address).font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("Title") {
                TextField("E.g. Sunset hike with Nish", text: $title)
            }

            Section("Notes") {
                TextField("What made this place special?", text: $notes, axis: .vertical)
                    .lineLimit(4...)
            }

            Section("Photos") {
                PhotosPicker(selection: $photoItems, maxSelectionCount: 10, matching: .images) {
                    Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                }
                .onChange(of: photoItems) { _, new in
                    Task { await loadPhotos(new) }
                }
                if !photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(photos.indices, id: \.self) { i in
                                Image(uiImage: photos[i])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Rating") {
                StarRatingView(rating: $rating)
                HStack {
                    Text("Placi Score Preview")
                    Spacer()
                    PlaciScoreBadge(score: previewScore)
                }
            }

            if let error = viewModel.errorMessage {
                Section { Text(error).foregroundStyle(.red).font(.caption) }
            }

            Section {
                Button("Post") { Task { await post(isDraft: false) } }
                    .frame(maxWidth: .infinity)
                    .disabled(title.isEmpty || viewModel.isSubmitting)
                Button("Save Draft") { Task { await post(isDraft: true) } }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
                    .disabled(viewModel.isSubmitting)
            }
        }
        .navigationTitle("New Post")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(viewModel.isSubmitting)
        .overlay { if viewModel.isSubmitting { ProgressView() } }
        .task { await loadExistingPosts() }
        .onChange(of: rating) { _, new in
            previewScore = RankingService.previewScore(existingPosts: existingPosts, draftRating: new)
        }
    }

    private func loadExistingPosts() async {
        guard let userId = authManager.currentUserId else { return }
        existingPosts = (try? await PostService.fetchUserPosts(userId: userId)) ?? []
        previewScore = RankingService.previewScore(existingPosts: existingPosts, draftRating: rating)
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        photos = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                photos.append(img)
            }
        }
    }

    private func post(isDraft: Bool) async {
        guard let userId = authManager.currentUserId else { return }
        do {
            _ = try await viewModel.submit(
                place: place,
                title: title,
                notes: notes,
                photos: photos,
                rating: rating,
                isDraft: isDraft,
                userId: userId
            )
            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
