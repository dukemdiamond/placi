import SwiftUI

struct MainTabView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @Environment(AuthManager.self) private var authManager
    @State private var unreadCount = 0

    var body: some View {
        @Bindable var appEnv = appEnv

        TabView(selection: $appEnv.selectedTab) {
            // FeedView manages its own NavigationStack internally
            FeedView()
                .tabItem { Label("feed", systemImage: "house.fill") }
                .tag(AppEnvironment.Tab.home)

            // MapTabView manages its own stack internally
            MapTabView()
                .tabItem { Label("map", systemImage: "map.fill") }
                .tag(AppEnvironment.Tab.map)

            AddPlaceView()
                .tabItem { Label("add", systemImage: "plus.circle.fill") }
                .tag(AppEnvironment.Tab.add)

            // Search needs its own NavigationStack as a tab root
            NavigationStack {
                SearchView()
            }
            .tabItem { Label("search", systemImage: "magnifyingglass") }
            .tag(AppEnvironment.Tab.search)

            // Profile needs its own NavigationStack as a tab root
            NavigationStack {
                ProfileView(userId: authManager.currentUserId ?? UUID())
            }
            .tabItem { Label("profile", systemImage: "person.fill") }
            .badge(unreadCount > 0 ? "\(unreadCount)" : nil)
            .tag(AppEnvironment.Tab.profile)
        }
        .tint(Color("PlaciAccent"))
        .task { await pollUnreadCount() }
        .onChange(of: appEnv.selectedTab) { _, new in
            if new == .profile && unreadCount > 0 {
                Task { await clearBadge() }
            }
        }
    }

    private func pollUnreadCount() async {
        guard let userId = authManager.currentUserId else { return }
        unreadCount = (try? await NotificationService.unreadCount(userId: userId)) ?? 0
    }

    private func clearBadge() async {
        guard let userId = authManager.currentUserId else { return }
        try? await NotificationService.markAllRead(userId: userId)
        unreadCount = 0
    }
}
