import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @Environment(AuthManager.self) private var authManager
    var onComplete: (Profile) -> Void

    @State private var username = ""
    @State private var displayName = ""
    @State private var bio = ""
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var usernameAvailable: Bool? = nil
    @State private var usernameCheckTask: Task<Void, Never>?

    var canSubmit: Bool {
        !username.isEmpty &&
        !displayName.isEmpty &&
        usernameAvailable == true &&
        !isLoading
    }

    var body: some View {
        NavigationStack {
            Form {
                // Avatar picker
                Section {
                    PhotosPicker(selection: $avatarItem, matching: .images) {
                        HStack(spacing: 16) {
                            if let img = avatarImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .foregroundStyle(.secondary)
                                    )
                            }
                            Text("Add profile photo")
                                .foregroundStyle(.primary)
                        }
                    }
                    .onChange(of: avatarItem) { _, new in
                        Task {
                            if let data = try? await new?.loadTransferable(type: Data.self),
                               let img = UIImage(data: data) {
                                avatarImage = img
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .onChange(of: username) { _, new in
                                checkUsernameDebounced(new)
                            }
                        Spacer()
                        usernameStatusIcon
                    }
                    TextField("Display name", text: $displayName)
                    TextField("Bio (optional)", text: $bio, axis: .vertical)
                        .lineLimit(3)
                } header: {
                    Text("Your info")
                } footer: {
                    if let available = usernameAvailable, !username.isEmpty {
                        Text(available ? "✓ @\(username) is available" : "✗ Username is taken")
                            .foregroundStyle(available ? .green : .red)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Set up your profile")
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { Task { await save() } }
                        .disabled(!canSubmit)
                }
            }
            .disabled(isLoading)
            .overlay { if isLoading { ProgressView() } }
        }
    }

    @ViewBuilder
    private var usernameStatusIcon: some View {
        if username.isEmpty {
            EmptyView()
        } else if usernameAvailable == nil {
            ProgressView().scaleEffect(0.7)
        } else if usernameAvailable == true {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        } else {
            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
        }
    }

    // MARK: - Username check

    private func checkUsernameDebounced(_ value: String) {
        usernameAvailable = nil
        usernameCheckTask?.cancel()
        guard !value.isEmpty else { return }
        usernameCheckTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            let taken = (try? await ProfileService.fetchProfile(username: value)) != nil
            usernameAvailable = !taken
        }
    }

    // MARK: - Save

    private func save() async {
        guard let userId = authManager.currentUserId else { return }
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            var avatarUrl: String? = nil
            if let img = avatarImage {
                let path = "avatars/\(userId.uuidString).jpg"
                if let data = img.jpegData(compressionQuality: 0.85) {
                    try await supabase.storage
                        .from("avatars")
                        .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
                    avatarUrl = try supabase.storage
                        .from("avatars")
                        .getPublicURL(path: path)
                        .absoluteString
                }
            }

            let payload = ProfileService.CreateProfilePayload(
                id: userId,
                username: username.lowercased().trimmingCharacters(in: .whitespaces),
                displayName: displayName.trimmingCharacters(in: .whitespaces),
                bio: bio.isEmpty ? nil : bio,
                avatarUrl: avatarUrl
            )
            let profile = try await ProfileService.createProfile(payload)
            onComplete(profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
