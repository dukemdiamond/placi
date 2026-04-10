import SwiftUI

struct FeedView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = FeedViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.posts.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "nothing here yet",
                        systemImage: "mappin.slash",
                        description: Text("follow people or add your first place.")
                    )
                } else {
                    List {
                        ForEach(viewModel.posts) { post in
                            NavigationLink(value: post) {
                                PostCardView(post: post)
                                    .onAppear {
                                        if post == viewModel.posts.last {
                                            Task { await viewModel.loadMore() }
                                        }
                                    }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                        }
                        if viewModel.isLoading {
                            HStack { Spacer(); ProgressView(); Spacer() }
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await viewModel.refresh() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("PlaciLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 26)
                }
            }
            .navigationDestination(for: Post.self) { post in
                PostDetailView(postId: post.id)
            }
            .navigationDestination(for: Profile.self) { profile in
                ProfileView(userId: profile.id)
            }
        }
        .task {
            if let userId = authManager.currentUserId {
                await viewModel.loadInitial(userId: userId)
            }
        }
        // Auto-refresh when a new post is created anywhere in the app
        .onChange(of: PostEvents.shared.latestPost?.id) { _, _ in
            Task {
                if let userId = authManager.currentUserId {
                    await viewModel.loadInitial(userId: userId)
                }
            }
        }
    }
}
