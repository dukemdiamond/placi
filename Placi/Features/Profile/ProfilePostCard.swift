import SwiftUI
import SDWebImageSwiftUI

/// Feed-style post card used on profile pages.
/// Format: "[Name] visited and ranked [Place]" with photo, notes, actions.
struct ProfilePostCard: View {
    let post: Post
    @Environment(AuthManager.self) private var authManager
    @State private var liked: Bool
    @State private var likeCount: Int
    @State private var showComments = false

    init(post: Post) {
        self.post = post
        _liked = State(initialValue: post.isLikedByCurrentUser)
        _likeCount = State(initialValue: post.likeCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header: "[Name] visited and ranked [Place]" ──
            HStack(alignment: .top, spacing: 10) {
                AvatarView(url: post.profile?.avatarUrl, name: post.profile?.displayName ?? "")
                    .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 3) {
                    visitedText
                    if let date = post.updatedAt as Date? {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.custom("Nunito-Regular", size: 11))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }

                Spacer()
                PlaciScoreBadge(score: post.placiScore)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // ── Photo ──
            if let photo = post.photos.first,
               let url = ImageService.publicURL(for: photo.storagePath) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 230)
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 10) {
                // ── Notes ──
                if let notes = post.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.custom("Nunito-Regular", size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                // ── Actions ──
                HStack(spacing: 22) {
                    Button {
                        liked.toggle()
                        likeCount += liked ? 1 : -1
                        Task {
                            guard let uid = authManager.currentUserId else { return }
                            if liked {
                                try? await PostService.likePost(postId: post.id, userId: uid)
                            } else {
                                try? await PostService.unlikePost(postId: post.id, userId: uid)
                            }
                        }
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

                    Button { showComments = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right")
                                .foregroundStyle(.secondary)
                            Text("\(post.commentCount)")
                                .font(.custom("Nunito-Regular", size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    ShareLink(
                        item: URL(string: "https://placi.app/post/\(post.id)")!,
                        message: Text("Check out \(post.place?.name ?? "this place") on placi 📍")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let rank = post.rankPosition {
                        Text("ranked #\(rank)")
                            .font(.custom("Nunito-SemiBold", size: 12))
                            .foregroundStyle(Color("PlaciAccent"))
                    }
                }
                .font(.system(size: 15))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
        .sheet(isPresented: $showComments) {
            PostDetailView(postId: post.id)
                .presentationDetents([.large])
        }
    }

    // "[Name] visited and ranked [Place Name]"
    private var visitedText: some View {
        Group {
            Text(post.profile?.displayName ?? "")
                .font(.custom("Nunito-Bold", size: 14))
            + Text(" visited and ranked ")
                .font(.custom("Nunito-Regular", size: 14))
            + Text(post.place?.name ?? "")
                .font(.custom("Nunito-Bold", size: 14))
                .foregroundColor(Color("PlaciAccent"))
        }
    }
}
