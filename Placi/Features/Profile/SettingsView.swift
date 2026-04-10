import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var isSaving = false
    @State private var showSignOutConfirm = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    PhotosPicker(selection: $avatarItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            if let img = avatarImage {
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(Circle())
                            } else {
                                AvatarView(url: authManager.profile?.avatarUrl,
                                           name: authManager.profile?.displayName ?? "")
                                    .frame(width: 72, height: 72)
                            }
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white)
                                .padding(5)
                                .background(Color("PlaciAccent"))
                                .clipShape(Circle())
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

                    VStack(alignment: .leading, spacing: 4) {
                        Text(authManager.profile?.username.map { "@\($0)" } ?? "")
                            .font(.custom("Nunito-SemiBold", size: 14))
                            .foregroundStyle(.secondary)
                        Text("tap photo to change")
                            .font(.custom("Nunito-Regular", size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("display name") {
                TextField("your name", text: $displayName)
                    .font(.custom("Nunito-Regular", size: 16))
            }

            if let error = errorMessage {
                Section {
                    Text(error).foregroundStyle(.red)
                        .font(.custom("Nunito-Regular", size: 14))
                }
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        Spacer()
                        Group {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("save changes")
                                    .font(.custom("Nunito-Bold", size: 16))
                            }
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color("PlaciAccent"))
                .foregroundStyle(.white)
                .disabled(displayName.isEmpty || isSaving)
            }

            Section {
                Button(role: .destructive) {
                    showSignOutConfirm = true
                } label: {
                    HStack {
                        Spacer()
                        Text("sign out")
                            .font(.custom("Nunito-SemiBold", size: 16))
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            displayName = authManager.profile?.displayName ?? ""
        }
        .confirmationDialog("sign out of placi?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("sign out", role: .destructive) {
                Task { try? await authManager.signOut() }
            }
        }
    }

    private func save() async {
        guard let userId = authManager.currentUserId else { return }
        isSaving = true
        defer { isSaving = false }
        errorMessage = nil
        do {
            var avatarUrl: String? = authManager.profile?.avatarUrl
            if let img = avatarImage,
               let data = img.jpegData(compressionQuality: 0.85) {
                let path = "avatars/\(userId.uuidString).jpg"
                try await supabase.storage.from("avatars")
                    .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
                avatarUrl = try supabase.storage.from("avatars").getPublicURL(path: path).absoluteString
            }
            let payload = ProfileService.UpdateProfilePayload(
                displayName: displayName,
                bio: authManager.profile?.bio,
                avatarUrl: avatarUrl
            )
            let updated = try await ProfileService.updateProfile(id: userId, payload: payload)
            authManager.profile = updated
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
