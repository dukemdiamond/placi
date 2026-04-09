import SwiftUI

struct PostDetailView: View {
    let postId: UUID
    @State private var viewModel = PostDetailViewModel()
    @Environment(AuthManager.self) private var authManager
    @State private var commentText = ""

    var body: some View {
        Group {
            if let post = viewModel.post {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Photo carousel
                        if !post.photos.isEmpty {
                            PhotoGridView(photos: post.photos)
                                .frame(height: 260)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(post.place?.name ?? "").font(.headline)
                                    Text(post.place?.address ?? "").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                PlaciScoreBadge(score: post.placiScore)
                            }

                            if let profile = post.profile {
                                HStack {
                                    AvatarView(url: profile.avatarUrl, name: profile.displayName)
                                        .frame(width: 36, height: 36)
                                    VStack(alignment: .leading) {
                                        Text(profile.displayName).font(.subheadline.bold())
                                        Text("@\(profile.username)").font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }

                            Text(post.title).font(.title3.bold())
                            if let notes = post.notes { Text(notes).font(.body) }

                            // Like / Comment / Share
                            HStack(spacing: 24) {
                                Button {
                                    Task { await viewModel.toggleLike(userId: authManager.currentUserId) }
                                } label: {
                                    Label("\(post.likeCount)", systemImage: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                                        .foregroundStyle(post.isLikedByCurrentUser ? .red : .secondary)
                                }
                                Label("\(post.commentCount)", systemImage: "bubble.right").foregroundStyle(.secondary)
                                Spacer()
                            }
                            .font(.subheadline)

                            Divider()

                            // Comments
                            ForEach(viewModel.comments) { comment in
                                CommentRowView(comment: comment)
                            }
                        }
                        .padding()
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    commentInputBar
                }
            } else if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load(postId: postId) }
    }

    private var commentInputBar: some View {
        HStack {
            TextField("Add a comment…", text: $commentText)
                .textFieldStyle(.roundedBorder)
            Button {
                Task {
                    await viewModel.addComment(body: commentText, userId: authManager.currentUserId)
                    commentText = ""
                }
            } label: {
                Image(systemName: "paperplane.fill")
            }
            .disabled(commentText.isEmpty)
        }
        .padding()
        .background(.regularMaterial)
    }
}

private struct CommentRowView: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            AvatarView(url: comment.profile?.avatarUrl, name: comment.profile?.displayName ?? "")
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(comment.profile?.displayName ?? "").font(.caption.bold())
                Text(comment.body).font(.subheadline)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
