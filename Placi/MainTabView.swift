import SwiftUI

struct MainTabView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        @Bindable var appEnv = appEnv

        TabView(selection: $appEnv.selectedTab) {
            FeedView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppEnvironment.Tab.home)

            MapTabView()
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(AppEnvironment.Tab.map)

            AddPlaceView()
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                .tag(AppEnvironment.Tab.add)

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(AppEnvironment.Tab.search)

            ProfileView(userId: authManager.currentUserId ?? UUID())
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(AppEnvironment.Tab.profile)
        }
        .tint(Color("PlaciAccent"))
    }
}
