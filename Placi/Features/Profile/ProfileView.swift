import SwiftUI

struct ProfileView: View {
    let userId: UUID
    @State private var viewModel = ProfileViewModel()
    @Environment(AuthManager.self) private var authManager

    var isOwnProfile: Bool { userId == authManager.currentUserId }

    var body: some View {
        NavigationStack {
            Group {
                if let profile = viewModel.profile {
                    profileContent(profile)
                } else if viewModel.isLoading {
                    ProgressView()
                } else {
                    ContentUnavailableView("Profile not found", systemImage: "person.slash")
                }
            }
            .navigationTitle(viewModel.profile.map { "@\($0.username)" } ?? "Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isOwnProfile {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            if let p = viewModel.profile { EditProfileView(profile: p) }
                        } label: {
                            Text("Edit")
                        }
                    }
                }
            }
        }
        .task { await viewModel.load(userId: userId) }
    }

    @ViewBuilder
    private func profileContent(_ profile: Profile) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    AvatarView(url: profile.avatarUrl, name: profile.displayName)
                        .frame(width: 80, height: 80)

                    Text(profile.displayName).font(.title2.bold())
                    Text("@\(profile.username)").font(.subheadline).foregroundStyle(.secondary)

                    if let bio = profile.bio {
                        Text(bio).font(.subheadline).multilineTextAlignment(.center).padding(.horizontal)
                    }

                    // Stats
                    HStack(spacing: 32) {
                        statView(value: viewModel.postCount, label: "Places")
                        statView(value: viewModel.followerCount, label: "Followers")
                        statView(value: viewModel.followingCount, label: "Following")
                    }
                    .padding(.top, 4)

                    if !isOwnProfile {
                        Button(viewModel.isFollowing ? "Following" : "Follow") {
                            Task { await viewModel.toggleFollow(currentUserId: authManager.currentUserId, targetId: userId) }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(viewModel.isFollowing ? .secondary : Color("PlaciAccent"))
                    }
                }
                .padding()

                Divider()

                // Tabs
                Picker("Section", selection: $viewModel.profileTab) {
                    Text("Posts").tag(ProfileViewModel.ProfileTab.posts)
                    Text("Ranked").tag(ProfileViewModel.ProfileTab.ranked)
                    Text("Lists").tag(ProfileViewModel.ProfileTab.lists)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                switch viewModel.profileTab {
                case .posts:
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.posts) { post in
                            NavigationLink(value: post) { PostCardView(post: post) }
                        }
                    }
                    .padding(.top, 8)
                case .ranked:
                    RankedListView(posts: $viewModel.posts, onReorder: { id, pos in
                        Task { await viewModel.reorder(postId: id, to: pos) }
                    })
                case .lists:
                    Text("Lists coming soon").foregroundStyle(.secondary).padding()
                }
            }
        }
        .navigationDestination(for: Post.self) { post in PostDetailView(postId: post.id) }
    }

    private func statView(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}
