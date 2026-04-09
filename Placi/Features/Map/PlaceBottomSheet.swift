import SwiftUI
import MapKit

struct PlaceBottomSheet: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !post.photos.isEmpty {
                PhotoGridView(photos: post.photos)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title).font(.headline)
                    if let address = post.place?.address {
                        Text(address).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                PlaciScoreBadge(score: post.placiScore)
            }

            if let notes = post.notes {
                Text(notes).font(.subheadline).foregroundStyle(.secondary)
            }

            if let place = post.place {
                Button {
                    openInMaps(place)
                } label: {
                    Label("Open in Maps", systemImage: "map")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private func openInMaps(_ place: Place) {
        let placemark = MKPlacemark(coordinate: place.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = place.name
        mapItem.openInMaps()
    }
}
