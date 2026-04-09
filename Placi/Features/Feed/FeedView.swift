import SwiftUI

struct FeedView: View {
    @State private var viewModel = FeedViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.posts.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView("No posts yet", systemImage: "mappin.slash", description: Text("Follow people or add your first place."))
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
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await viewModel.refresh() }
                }
            }
            .navigationTitle("Home")
            .navigationDestination(for: Post.self) { post in
                PostDetailView(postId: post.id)
            }
        }
        .task { await viewModel.loadInitial() }
    }
}
