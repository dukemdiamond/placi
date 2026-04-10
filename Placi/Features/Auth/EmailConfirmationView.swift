import SwiftUI

struct EmailConfirmationView: View {
    let email: String
    @Environment(AuthManager.self) private var authManager
    @State private var isResending = false
    @State private var resendSuccess = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "envelope.badge.checkmark.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color("PlaciAccent"))

            VStack(spacing: 12) {
                Text("Verify your email")
                    .font(.custom("Nunito-Bold", size: 26))
                Text("We sent a confirmation link to")
                    .font(.custom("Nunito-Regular", size: 16))
                    .foregroundStyle(.secondary)
                Text(email)
                    .font(.custom("Nunito-SemiBold", size: 16))
                    .foregroundStyle(Color("PlaciAccent"))
                Text("Tap the link in the email to activate your account, then come back and sign in.")
                    .font(.custom("Nunito-Regular", size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 12) {
                if resendSuccess {
                    Label("Email resent!", systemImage: "checkmark.circle.fill")
                        .font(.custom("Nunito-SemiBold", size: 15))
                        .foregroundStyle(.green)
                }

                Button {
                    Task { await resend() }
                } label: {
                    Group {
                        if isResending {
                            ProgressView().tint(.white)
                        } else {
                            Text("Resend confirmation email")
                                .font(.custom("Nunito-SemiBold", size: 16))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("PlaciAccent"))
                .disabled(isResending)
                .padding(.horizontal)

                Button("Back to Sign In") {
                    authManager.awaitingConfirmation = false
                    authManager.pendingEmail = nil
                }
                .font(.custom("Nunito-Regular", size: 15))
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private func resend() async {
        isResending = true
        defer { isResending = false }
        try? await supabase.auth.resend(email: email, type: .signup)
        resendSuccess = true
    }
}
