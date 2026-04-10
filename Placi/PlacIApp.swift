import SwiftUI

@main
struct PlacIApp: App {
    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .preferredColorScheme(.light)
                // Apply Nunito as the default font throughout the app
                .font(.custom("Nunito-Regular", size: 17, relativeTo: .body))
        }
    }
}
