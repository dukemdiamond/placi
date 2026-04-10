import SwiftUI

struct FollowerListView: View {
    let userId: UUID
    @State private var followers: [Profile] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if followers.isEmpty {
                ContentUnavailableView("no followers yet", systemImage: "person.2.slash")
            } else {
                List(followers) { profile in
                    NavigationLink(value: profile) {
                        UserRowView(profile: profile)
                    }
                }
                .listStyle(.plain)
                .navigationDestination(for: Profile.self) { ProfileView(userId: $0.id) }
            }
        }
        .navigationTitle("followers")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            followers = (try? await ProfileService.fetchFollowers(userId: userId)) ?? []
            isLoading = false
        }
    }
}
