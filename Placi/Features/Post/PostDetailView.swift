import SwiftUI

struct PostDetailView: View {
    let postId: UUID
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = PostDetailViewModel()
    @State private var commentText = ""
    @FocusState private var commentFocused: Bool

    var body: some View {
        Group {
            if let post = viewModel.post {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // Photo carousel
                        if !post.photos.isEmpty {
                            PhotoGridView(photos: post.photos)
                                .frame(height: 280)
                        }

                        VStack(alignment: .leading, spacing: 14) {

                            // Place + score
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(post.place?.name ?? "").font(.title3.bold())
                                    if let address = post.place?.address {
                                        Text(address).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                PlaciScoreBadge(score: post.placiScore)
                            }

                            // Author row
                            if let profile = post.profile {
                                NavigationLink(value: profile) {
                                    HStack(spacing: 10) {
                                        AvatarView(url: profile.avatarUrl, name: profile.displayName)
                                            .frame(width: 36, height: 36)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(profile.displayName).font(.subheadline.bold())
                                            Text("@\(profile.username)").font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(post.createdAt.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tint(.primary)
                            }

                            Divider()

                            // Title + notes
                            Text(post.title).font(.headline)
                            if let notes = post.notes, !notes.isEmpty {
                                Text(notes).font(.body).foregroundStyle(.secondary)
                            }

                            // Rating
                            HStack {
                                Image(systemName: "star.fill").foregroundStyle(.yellow)
                                Text("\(post.baseRating) / 10").font(.subheadline)
                            }

                            // Actions
                            HStack(spacing: 24) {
                                Button {
                                    Task { await viewModel.toggleLike(userId: authManager.currentUserId) }
                                } label: {
                                    Label("\(post.likeCount)", systemImage: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                                        .foregroundStyle(post.isLikedByCurrentUser ? .red : .secondary)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    commentFocused = true
                                } label: {
                                    Label("\(post.commentCount)", systemImage: "bubble.right")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    Task { await viewModel.sharePost(userId: authManager.currentUserId) }
                                } label: {
                                    Image(systemName: "arrowshape.turn.up.right")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)

                                Spacer()
                            }
                            .font(.subheadline)

                            Divider()

                            // Comments
                            if viewModel.comments.isEmpty {
                                Text("No comments yet. Be the first!")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(viewModel.comments) { comment in
                                    CommentRowView(comment: comment)
                                    Divider()
                                }
                            }
                        }
                        .padding()
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    commentInputBar
                }
                .navigationDestination(for: Profile.self) { profile in
                    ProfileView(userId: profile.id)
                }
            } else if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView("Post not found", systemImage: "doc.slash")
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load(postId: postId) }
    }

    private var commentInputBar: some View {
        HStack(spacing: 10) {
            AvatarView(url: authManager.profile?.avatarUrl, name: authManager.profile?.displayName ?? "")
                .frame(width: 28, height: 28)
            TextField("Add a comment…", text: $commentText)
                .textFieldStyle(.roundedBorder)
                .focused($commentFocused)
                .submitLabel(.send)
                .onSubmit { submitComment() }
            Button(action: submitComment) {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(commentText.isEmpty ? .secondary : Color("PlaciAccent"))
            }
            .disabled(commentText.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private func submitComment() {
        let body = commentText
        guard !body.isEmpty else { return }
        commentText = ""
        commentFocused = false
        Task {
            await viewModel.addComment(body: body, userId: authManager.currentUserId)
        }
    }
}

// MARK: - Comment row

private struct CommentRowView: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AvatarView(url: comment.profile?.avatarUrl, name: comment.profile?.displayName ?? "")
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(comment.profile?.displayName ?? "").font(.subheadline.bold())
                    Text(comment.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(comment.body).font(.subheadline)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
