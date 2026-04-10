import SwiftUI

struct FeedView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(AppEnvironment.self) private var appEnv
    @State private var viewModel = FeedViewModel()
    @State private var showSearch = false

    var body: some View {
        // @Bindable must be at body scope, not inside a closure
        @Bindable var appEnv = appEnv

        NavigationStack {
            feedContent
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { feedToolbar(appEnv: $appEnv.selectedTab) }
                .navigationDestination(for: Post.self) { PostDetailView(postId: $0.id) }
                .navigationDestination(for: Profile.self) { ProfileView(userId: $0.id) }
        }
        .sheet(isPresented: $showSearch) {
            SearchView().presentationDetents([.large])
        }
        .task {
            if let id = authManager.currentUserId {
                await viewModel.loadInitial(userId: id)
            }
        }
        .onChange(of: PostEvents.shared.latestPost?.id) { _, _ in
            Task {
                if let id = authManager.currentUserId {
                    await viewModel.loadInitial(userId: id)
                }
            }
        }
    }

    // MARK: - Feed content

    private var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                searchBar
                if !viewModel.suggestedUsers.isEmpty {
                    SuggestedUsersSection(users: viewModel.suggestedUsers)
                        .padding(.bottom, 8)
                }
                postsList
            }
            .padding(.top, 4)
        }
        .refreshable { await viewModel.refresh() }
    }

    private var searchBar: some View {
        Button { showSearch = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
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
    }

    @ViewBuilder
    private var postsList: some View {
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
                        onLike: { Task { await viewModel.toggleLike(post: post) } })
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

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func feedToolbar(appEnv: Binding<AppEnvironment.Tab>) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Image("PlaciLogo")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(height: 30)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                appEnv.wrappedValue = .map
            } label: {
                Image(systemName: "map")
                    .font(.system(size: 18))
                    .foregroundStyle(Color("PlaciAccent"))
            }
            NavigationLink {
                NotificationsView()
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundStyle(Color("PlaciAccent"))
            }
        }
    }
}

// MARK: - Suggested Users

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
