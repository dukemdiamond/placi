import SwiftUI

struct UserRowView: View {
    let profile: Profile

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: profile.avatarUrl, name: profile.displayName)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName).font(.subheadline.bold())
                Text("@\(profile.username)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
