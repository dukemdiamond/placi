import Foundation
import Observation
import Supabase

@Observable
final class AuthManager {
    var session: Session?
    var isLoading = false
    var errorMessage: String?

    var isAuthenticated: Bool { session != nil }
    var currentUserId: UUID? { session?.user.id }

    init() {
        Task { await observeAuthState() }
    }

    // MARK: - Auth State

    private func observeAuthState() async {
        for await (event, session) in await supabase.auth.authStateChanges {
            switch event {
            case .signedIn, .tokenRefreshed, .userUpdated:
                self.session = session
            case .signedOut:
                self.session = nil
            default:
                break
            }
        }
    }

    // MARK: - Sign In / Sign Up

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let response = try await supabase.auth.signIn(email: email, password: password)
        session = response.session
    }

    func signUp(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let response = try await supabase.auth.signUp(email: email, password: password)
        session = response.session
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        session = nil
    }
}
