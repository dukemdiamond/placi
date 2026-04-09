import SwiftUI
import SDWebImageSwiftUI

struct AvatarView: View {
    let url: String?
    let name: String

    var body: some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                WebImage(url: imageURL)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Color("PlaciAccent").opacity(0.2))
                    .overlay(
                        Text(initials(from: name))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color("PlaciAccent"))
                    )
            }
        }
        .clipShape(Circle())
    }

    private func initials(from name: String) -> String {
        let words = name.split(separator: " ")
        let letters = words.prefix(2).compactMap { $0.first.map { String($0) } }
        return letters.joined().uppercased()
    }
}
