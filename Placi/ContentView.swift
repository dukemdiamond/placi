import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var appEnv = AppEnvironment()

    var body: some View {
        Group {
            if !authManager.hasResolved {
                // Splash — wait for session check before routing
                splashView
            } else if authManager.needsOnboarding {
                OnboardingView { profile in
                    authManager.profile = profile
                }
            } else if authManager.isAuthenticated {
                MainTabView()
                    .environment(appEnv)
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.hasResolved)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authManager.needsOnboarding)
    }

    private var splashView: some View {
        VStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color("PlaciAccent"))
            Text("Placi")
                .font(.largeTitle.bold())
        }
    }
}
