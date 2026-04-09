import SwiftUI

struct LeaderboardView: View {
    @State private var tab: Tab = .friends
    @State private var sort: Sort = .placesLogged
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = false
    @Environment(AuthManager.self) private var authManager

    enum Tab: String, CaseIterable { case friends = "Friends"; case global = "Global" }
    enum Sort: String, CaseIterable { case placesLogged = "Places"; case avgScore = "Avg Score" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                Picker("Sort", selection: $sort) {
                    ForEach(Sort.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                if isLoading {
                    ProgressView().padding()
                } else if entries.isEmpty {
                    ContentUnavailableView(
                        "No data yet",
                        systemImage: "trophy",
                        description: Text("Follow people to see the Friends leaderboard.")
                    )
                } else {
                    List {
                        ForEach(Array(entries.enumerated()), id: \.offset) { i, entry in
                            NavigationLink {
                                ProfileView(userId: entry.profile.id)
                            } label: {
                                HStack {
                                    Text("#\(i + 1)")
                                        .font(.headline.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 36)
                                    UserRowView(profile: entry.profile)
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(entry.postCount)")
                                            .font(.subheadline.bold())
                                        Text("places").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Leaderboard")
            .task { await load() }
            .onChange(of: tab) { _, _ in Task { await load() } }
            .onChange(of: sort) { _, _ in Task { await load() } }
        }
    }

    private func load() async {
        guard let userId = authManager.currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            // For friends tab: get following IDs, fetch their posts, aggregate
            if tab == .friends {
                let rows: [FollowingRow] = try await supabase
                    .from("follows")
                    .select("following_id")
                    .eq("follower_id", value: userId)
                    .execute()
                    .value
                let ids = rows.map(\.followingId)
                guard !ids.isEmpty else { entries = []; return }

                let profiles: [Profile] = try await supabase
                    .from("profiles")
                    .select()
                    .in("id", values: ids)
                    .execute()
                    .value

                var result: [LeaderboardEntry] = []
                for profile in profiles {
                    let posts = try await PostService.fetchUserPosts(userId: profile.id)
                    result.append(LeaderboardEntry(profile: profile, postCount: posts.count))
                }
                entries = result.sorted { $0.postCount > $1.postCount }
            } else {
                // Global: top 50 profiles by post count via a simple query
                let profiles: [Profile] = try await supabase
                    .from("profiles")
                    .select()
                    .limit(50)
                    .execute()
                    .value

                var result: [LeaderboardEntry] = []
                for profile in profiles {
                    let posts = try await PostService.fetchUserPosts(userId: profile.id)
                    result.append(LeaderboardEntry(profile: profile, postCount: posts.count))
                }
                entries = result.sorted { $0.postCount > $1.postCount }
            }
        } catch {
            entries = []
        }
    }
}

private struct LeaderboardEntry {
    let profile: Profile
    let postCount: Int
}

private struct FollowingRow: Decodable {
    let followingId: String
    enum CodingKeys: String, CodingKey { case followingId = "following_id" }
}
