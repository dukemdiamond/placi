import Foundation
import Observation
import AuthenticationServices
import Supabase

@Observable
final class AuthManager {
    var session: Session?
    var profile: Profile?
    var isLoading = false

    /// True once the initial session check has completed (prevents flash of login screen)
    var hasResolved = false

    var isAuthenticated: Bool { session != nil }
    var currentUserId: UUID? { session?.user.id }
    /// New users who are signed in but have no profile row yet
    var needsOnboarding: Bool { isAuthenticated && profile == nil && hasResolved }

    init() {
        Task { await observeAuthState() }
    }

    // MARK: - Auth State

    private func observeAuthState() async {
        // authStateChanges is a plain AsyncStream in supabase-swift v2 — no `await` needed
        for await (event, session) in supabase.auth.authStateChanges {
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
        // signIn returns Session directly in supabase-swift v2
        let session = try await supabase.auth.signIn(email: email, password: password)
        self.session = session
        await loadProfile(userId: session.user.id)
    }

    func signUp(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        // signUp returns AuthResponse; session is optional (nil until email confirmed)
        let response = try await supabase.auth.signUp(email: email, password: password)
        self.session = response.session
        // profile stays nil → needsOnboarding = true once session is set
    }

    // MARK: - Apple Sign In

    func signInWithApple(idToken: String, nonce: String) async throws {
        isLoading = true
        defer { isLoading = false }
        // signInWithIdToken returns Session directly in supabase-swift v2
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        self.session = session
        await loadProfile(userId: session.user.id)
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await supabase.auth.signOut()
        session = nil
        profile = nil
    }
}
