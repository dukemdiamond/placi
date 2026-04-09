import SwiftUI
import SDWebImageSwiftUI

struct PostCardView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Leading photo
            if let photo = post.photos.first,
               let url = ImageService.publicURL(for: photo.storagePath) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    AvatarView(url: post.profile?.avatarUrl, name: post.profile?.displayName ?? "")
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(post.profile?.displayName ?? "").font(.subheadline.bold())
                        Text("@\(post.profile?.username ?? "")").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    PlaciScoreBadge(score: post.placiScore)
                }

                Text(post.title).font(.headline)
                if let place = post.place {
                    Text(place.name).font(.subheadline).foregroundStyle(Color("PlaciAccent"))
                }
                if let notes = post.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 16) {
                    Label("\(post.likeCount)", systemImage: "heart")
                    Label("\(post.commentCount)", systemImage: "bubble.right")
                    Spacer()
                    Text(post.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 12)
    }
}
