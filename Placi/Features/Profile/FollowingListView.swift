import SwiftUI

struct FollowingListView: View {
    let userId: UUID
    @State private var following: [Profile] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if following.isEmpty {
                ContentUnavailableView("not following anyone yet", systemImage: "person.slash")
            } else {
                List(following) { profile in
                    NavigationLink(value: profile) {
                        UserRowView(profile: profile)
                    }
                }
                .listStyle(.plain)
                .navigationDestination(for: Profile.self) { ProfileView(userId: $0.id) }
            }
        }
        .navigationTitle("following")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            following = (try? await ProfileService.fetchFollowing(userId: userId)) ?? []
            isLoading = false
        }
    }
}
