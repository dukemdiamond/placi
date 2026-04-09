import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var appEnv = AppEnvironment()

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .environment(appEnv)
            } else {
                AuthView()
            }
        }
    }
}
