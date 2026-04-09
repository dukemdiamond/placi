import SwiftUI

struct AuthView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Logo / wordmark
                VStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color("PlaciAccent"))
                    Text("Placi")
                        .font(.largeTitle.bold())
                }

                Spacer()

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .textFieldStyle(.roundedBorder)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button(isSignUp ? "Create Account" : "Sign In") {
                        Task { await submit() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("PlaciAccent"))
                    .frame(maxWidth: .infinity)
                    .disabled(authManager.isLoading)
                    .overlay {
                        if authManager.isLoading { ProgressView() }
                    }

                    Button(isSignUp ? "Already have an account? Sign In" : "New to Placi? Sign Up") {
                        isSignUp.toggle()
                        errorMessage = nil
                    }
                    .font(.footnote)
                    .foregroundStyle(Color("PlaciAccent"))
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarHidden(true)
        }
    }

    private func submit() async {
        errorMessage = nil
        do {
            if isSignUp {
                try await authManager.signUp(email: email, password: password)
            } else {
                try await authManager.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
