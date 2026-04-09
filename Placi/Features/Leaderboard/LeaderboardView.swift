import SwiftUI

struct LeaderboardView: View {
    @State private var tab: Tab = .friends
    @State private var sort: Sort = .placesLogged
    @State private var profiles: [Profile] = []

    enum Tab: String, CaseIterable { case friends = "Friends"; case global = "Global" }
    enum Sort: String, CaseIterable { case placesLogged = "Places"; case avgScore = "Avg Score"; case countries = "Countries" }

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

                List(Array(profiles.enumerated()), id: \.element.id) { i, profile in
                    NavigationLink {
                        ProfileView(userId: profile.id)
                    } label: {
                        HStack {
                            Text("#\(i + 1)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 36)
                            UserRowView(profile: profile)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Leaderboard")
        }
    }
}
