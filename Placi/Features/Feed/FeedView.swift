import SwiftUI

struct FeedView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(AppEnvironment.self) private var appEnv
    @State private var viewModel = FeedViewModel()
    @State private var searchText = ""
    @State private var showSearch = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Search bar
                    Button { showSearch = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            Text("search a place, member, niche…")
                                .font(.custom("Nunito-Regular", size: 15))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)

                    // Suggested users (shown while feed is sparse)
                    if !viewModel.suggestedUsers.isEmpty {
                        SuggestedUsersSection(users: viewModel.suggestedUsers)
                            .padding(.bottom, 8)
                    }

                    if viewModel.posts.isEmpty && !viewModel.isLoading {
                        ContentUnavailableView(
                            "nothing here yet",
                            systemImage: "mappin.slash",
                            description: Text("follow people or add your first place.")
                        )
                        .padding(.top, 60)
                    } else {
                        ForEach(viewModel.posts) { post in
                            NavigationLink(value: post) {
                                PostCardView(post: post,
                                    onLike: { Task { await viewModel.toggleLike(post: post) } }
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.bottom, 14)
                            .onAppear {
                                if post == viewModel.posts.last {
                                    Task { await viewModel.loadMore() }
                                }
                            }
                        }

                        if viewModel.isLoading {
                            ProgressView().padding()
                        }
                    }
                }
                .padding(.top, 4)
            }
            .refreshable { await viewModel.refresh() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image("PlaciLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 34)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        @Bindable var appEnv = appEnv
                        appEnv.selectedTab = .map
                    } label: {
                        Image(systemName: "map")
                            .foregroundStyle(Color("PlaciAccent"))
                    }
                    NavigationLink {
                        NotificationsView()
                    } label: {
                        Image(systemName: "bell")
                            .foregroundStyle(Color("PlaciAccent"))
                    }
                }
            }
            .navigationDestination(for: Post.self) { post in
                PostDetailView(postId: post.id)
            }
            .navigationDestination(for: Profile.self) { profile in
                ProfileView(userId: profile.id)
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
                .presentationDetents([.large])
        }
        .task {
            if let userId = authManager.currentUserId {
                await viewModel.loadInitial(userId: userId)
            }
        }
        .onChange(of: PostEvents.shared.latestPost?.id) { _, _ in
            Task {
                if let userId = authManager.currentUserId {
                    await viewModel.loadInitial(userId: userId)
                }
            }
        }
    }
}

// MARK: - Suggested Users Section

struct SuggestedUsersSection: View {
    let users: [Profile]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("suggested")
                .font(.custom("Nunito-Bold", size: 15))
                .foregroundStyle(.secondary)
                .padding(.leading, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(users) { user in
                        NavigationLink(value: user) {
                            VStack(spacing: 6) {
                                AvatarView(url: user.avatarUrl, name: user.displayName)
                                    .frame(width: 56, height: 56)
                                Text("@\(user.username)")
                                    .font(.custom("Nunito-SemiBold", size: 12))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                            }
                            .frame(width: 70)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
        .padding(.bottom, 6)
    }
}
