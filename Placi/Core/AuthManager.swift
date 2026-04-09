import Foundation
import Observation
import AuthenticationServices
import Supabase

@Observable
final class AuthManager {
    var session: Session?
    var profile: Profile?
    var isLoading = false
    var errorMessage: String?

    /// True once the auth state has been checked at least once (prevents flash of login screen)
    var hasResolved = false

    var isAuthenticated: Bool { session != nil }
    var currentUserId: UUID? { session?.user.id }
    /// New users who are signed in but haven't created a profile yet
    var needsOnboarding: Bool { isAuthenticated && profile == nil && hasResolved }

    init() {
        Task { await observeAuthState() }
    }

    // MARK: - Auth State

    private func observeAuthState() async {
        for await (event, session) in await supabase.auth.authStateChanges {
            switch event {
            case .initialSession:
                self.session = session
                if let session {
                    await loadProfile(userId: session.user.id)
                }
                hasResolved = true
            case .signedIn, .tokenRefreshed, .userUpdated:
                self.session = session
                if let session {
                    await loadProfile(userId: session.user.id)
                }
            case .signedOut:
                self.session = nil
                self.profile = nil
            default:
                break
            }
        }
    }

    func loadProfile(userId: UUID) async {
        profile = try? await ProfileService.fetchProfile(id: userId)
    }

    // MARK: - Email Auth

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let response = try await supabase.auth.signIn(email: email, password: password)
        session = response.session
        if let uid = response.session?.user.id {
            await loadProfile(userId: uid)
        }
    }

    func signUp(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let response = try await supabase.auth.signUp(email: email, password: password)
        session = response.session
        // profile stays nil → needsOnboarding = true
    }

    // MARK: - Apple Sign In

    func signInWithApple(idToken: String, nonce: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let response = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        session = response.session
        if let uid = response.session?.user.id {
            await loadProfile(userId: uid)
        }
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await supabase.auth.signOut()
        session = nil
        profile = nil
    }
}
