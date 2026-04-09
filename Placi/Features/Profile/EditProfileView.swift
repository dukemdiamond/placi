import SwiftUI
import PhotosUI

struct EditProfileView: View {
    let profile: Profile
    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String
    @State private var bio: String
    @State private var avatarItem: PhotosPickerItem?
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(profile: Profile) {
        self.profile = profile
        _displayName = State(initialValue: profile.displayName)
        _bio = State(initialValue: profile.bio ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $avatarItem, matching: .images) {
                        Label("Change Photo", systemImage: "camera")
                    }
                }
                Section {
                    TextField("Display Name", text: $displayName)
                    TextField("Bio", text: $bio, axis: .vertical).lineLimit(3)
                }
                if let error = errorMessage {
                    Section { Text(error).foregroundStyle(.red).font(.caption) }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(displayName.isEmpty || isSaving)
                }
            }
            .disabled(isSaving)
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let payload = ProfileService.UpdateProfilePayload(
            displayName: displayName,
            bio: bio.isEmpty ? nil : bio,
            avatarUrl: nil
        )
        do {
            _ = try await ProfileService.updateProfile(id: profile.id, payload: payload)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
