import SwiftUI
import SDWebImageSwiftUI

struct PostCardView: View {
    let post: Post
    var onLike: (() -> Void)? = nil

    @State private var liked: Bool
    @State private var likeCount: Int

    init(post: Post, onLike: (() -> Void)? = nil) {
        self.post = post
        self.onLike = onLike
        _liked = State(initialValue: post.isLikedByCurrentUser)
        _likeCount = State(initialValue: post.likeCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photo
            if let photo = post.photos.first,
               let url = ImageService.publicURL(for: photo.storagePath) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .overlay(alignment: .topTrailing) {
                        PlaciScoreBadge(score: post.placiScore)
                            .padding(10)
                    }
            }

            VStack(alignment: .leading, spacing: 10) {
                // Author + score (no photo case)
                HStack(spacing: 10) {
                    NavigationLink(value: post.profile) {
                        AvatarView(url: post.profile?.avatarUrl, name: post.profile?.displayName ?? "")
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(post.profile?.displayName ?? "")
                            .font(.custom("Nunito-Bold", size: 14))
                        Text("@\(post.profile?.username ?? "")")
                            .font(.custom("Nunito-Regular", size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if post.photos.isEmpty {
                        PlaciScoreBadge(score: post.placiScore)
                    }
                }

                // Place name
                if let place = post.place {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color("PlaciAccent"))
                        Text(place.name)
                            .font(.custom("Nunito-SemiBold", size: 14))
                            .foregroundStyle(Color("PlaciAccent"))
                    }
                }

                // Title
                Text(post.title)
                    .font(.custom("Nunito-Bold", size: 16))

                // Rank context
                if let rank = post.rankPosition {
                    Text("ranked #\(rank) in their list")
                        .font(.custom("Nunito-Regular", size: 12))
                        .foregroundStyle(.secondary)
                }

                // Notes
                if let notes = post.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.custom("Nunito-Regular", size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                // Actions
                HStack(spacing: 20) {
                    // Like — tappable inline without opening post
                    Button {
                        liked.toggle()
                        likeCount += liked ? 1 : -1
                        onLike?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: liked ? "heart.fill" : "heart")
                                .foregroundStyle(liked ? .red : .secondary)
                            Text("\(max(0, likeCount))")
                                .font(.custom("Nunito-Regular", size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundStyle(.secondary)
                        Text("\(post.commentCount)")
                            .font(.custom("Nunito-Regular", size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(post.createdAt.formatted(.relative(presentation: .named)))
                        .font(.custom("Nunito-Regular", size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 14)
    }
}
