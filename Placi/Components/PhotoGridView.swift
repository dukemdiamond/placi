import SwiftUI
import SDWebImageSwiftUI

struct PhotoGridView: View {
    let photos: [PostPhoto]

    var body: some View {
        TabView {
            ForEach(photos.sorted { $0.displayOrder < $1.displayOrder }) { photo in
                if let url = ImageService.publicURL(for: photo.storagePath) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    Color.secondary.opacity(0.2)
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                }
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}
