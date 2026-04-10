import SwiftUI

struct WantToGoCard: View {
    let place: Place
    let userId: UUID?
    @State private var removed = false

    var body: some View {
        if !removed {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color("PlaciAccent").opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "mappin.fill")
                        .foregroundStyle(Color("PlaciAccent"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.custom("Nunito-Bold", size: 15))
                        .foregroundStyle(.primary)
                    if let address = place.address {
                        Text(address)
                            .font(.custom("Nunito-Regular", size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    guard let uid = userId else { return }
                    Task {
                        try? await BookmarkService.removeBookmark(userId: uid, placeId: place.id)
                        withAnimation { removed = true }
                    }
                } label: {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(Color("PlaciAccent"))
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}
