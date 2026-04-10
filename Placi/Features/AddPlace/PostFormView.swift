import SwiftUI
import PhotosUI

struct PostFormView: View {
    let place: Place
    @Bindable var viewModel: AddPlaceViewModel
    var onPosted: (Post) -> Void

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
            Section("place") {
                Text(place.name).font(.custom("Nunito-SemiBold", size: 16))
                if let address = place.address {
                    Text(address)
                        .font(.custom("Nunito-Regular", size: 14))
                        .foregroundStyle(.secondary)
                }
            }

            Section("title") {
                TextField("e.g. sunset hike with Nish", text: $title)
                    .font(.custom("Nunito-Regular", size: 16))
            }

            Section("notes") {
                TextField("what made this place special?", text: $notes, axis: .vertical)
                    .lineLimit(4...)
                    .font(.custom("Nunito-Regular", size: 16))
            }

            Section("photos") {
                PhotosPicker(selection: $photoItems, maxSelectionCount: 10, matching: .images) {
                    Label("add photos", systemImage: "photo.on.rectangle.angled")
                        .font(.custom("Nunito-Regular", size: 16))
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

            Section("rating") {
                StarRatingView(rating: $rating)
                HStack {
                    Text("placi score preview")
                        .font(.custom("Nunito-Regular", size: 15))
                    Spacer()
                    PlaciScoreBadge(score: previewScore)
                }
            }

            if let error = viewModel.errorMessage {
                Section { Text(error).foregroundStyle(.red).font(.custom("Nunito-Regular", size: 14)) }
            }

            Section {
                Button {
                    Task { await post(isDraft: false) }
                } label: {
                    Group {
                        if viewModel.isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("post")
                                .font(.custom("Nunito-Bold", size: 17))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("PlaciAccent"))
                .disabled(title.isEmpty || viewModel.isSubmitting)
                .listRowInsets(EdgeInsets())

                Button("save draft") {
                    Task { await post(isDraft: true) }
                }
                .font(.custom("Nunito-Regular", size: 16))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.isSubmitting)
            }
        }
        .navigationTitle("new post")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(viewModel.isSubmitting)
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
            let newPost = try await viewModel.submit(
                place: place,
                title: title,
                notes: notes,
                photos: photos,
                rating: rating,
                isDraft: isDraft,
                userId: userId
            )
            if !isDraft {
                PostEvents.shared.postCreated(newPost)
                onPosted(newPost)
            } else {
                dismiss()
            }
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
