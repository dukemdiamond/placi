import SwiftUI
import MapKit

struct PlaceBottomSheet: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @State private var isBookmarked = false
    @State private var bookmarkLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Photos
            if !post.photos.isEmpty {
                PhotoGridView(photos: post.photos)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Place + score
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title)
                        .font(.custom("Nunito-Bold", size: 17))
                    if let address = post.place?.address {
                        Text(address)
                            .font(.custom("Nunito-Regular", size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                PlaciScoreBadge(score: post.placiScore)
            }

            if let notes = post.notes {
                Text(notes)
                    .font(.custom("Nunito-Regular", size: 14))
                    .foregroundStyle(.secondary)
            }

            // Been / Want to Go / Open in Maps
            HStack(spacing: 10) {
                // Been — opens post detail
                NavigationLink(value: post) {
                    Label("been", systemImage: "checkmark.circle.fill")
                        .font(.custom("Nunito-SemiBold", size: 14))
                        .frame(maxWidth: .infinity, minHeight: 38)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("PlaciAccent"))

                // Want to Go — bookmark
                Button {
                    Task { await toggleBookmark() }
                } label: {
                    Label(
                        isBookmarked ? "saved" : "want to go",
                        systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                    )
                    .font(.custom("Nunito-SemiBold", size: 14))
                    .frame(maxWidth: .infinity, minHeight: 38)
                }
                .buttonStyle(.bordered)
                .tint(Color("PlaciAccent"))
                .disabled(bookmarkLoading)
            }

            // Open in Maps
            if let place = post.place {
                Button {
                    openInMaps(place)
                } label: {
                    Label("open in maps", systemImage: "map")
                        .font(.custom("Nunito-Regular", size: 15))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .task { await checkBookmark() }
    }

    private func checkBookmark() async {
        guard let uid = authManager.currentUserId,
              let placeId = post.place?.id else { return }
        isBookmarked = (try? await BookmarkService.isBookmarked(userId: uid, placeId: placeId)) ?? false
    }

    private func toggleBookmark() async {
        guard let uid = authManager.currentUserId,
              let placeId = post.place?.id else { return }
        bookmarkLoading = true
        defer { bookmarkLoading = false }
        do {
            if isBookmarked {
                try await BookmarkService.removeBookmark(userId: uid, placeId: placeId)
            } else {
                try await BookmarkService.addBookmark(userId: uid, placeId: placeId)
            }
            isBookmarked.toggle()
        } catch {}
    }

    private func openInMaps(_ place: Place) {
        let placemark = MKPlacemark(coordinate: place.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = place.name
        mapItem.openInMaps()
    }
}
