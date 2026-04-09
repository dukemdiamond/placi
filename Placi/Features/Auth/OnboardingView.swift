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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $avatarItem, matching: .images) {
                        HStack {
                            if let img = avatarImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .overlay(Image(systemName: "camera.fill").foregroundStyle(.secondary))
                            }
                            Text("Choose photo")
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

                Section("Your info") {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                    TextField("Display name", text: $displayName)
                    TextField("Bio (optional)", text: $bio, axis: .vertical)
                        .lineLimit(3)
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Set up your profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { Task { await save() } }
                        .disabled(username.isEmpty || displayName.isEmpty || isLoading)
                }
            }
            .disabled(isLoading)
            .overlay { if isLoading { ProgressView() } }
        }
    }

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
                    try await supabase.storage.from("avatars")
                        .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
                    avatarUrl = try supabase.storage.from("avatars").getPublicURL(path: path).absoluteString
                }
            }

            let payload = ProfileService.CreateProfilePayload(
                id: userId,
                username: username.lowercased(),
                displayName: displayName,
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
