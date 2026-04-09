import SwiftUI

struct NotificationsView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && notifications.isEmpty {
                    ProgressView()
                } else if notifications.isEmpty {
                    ContentUnavailableView("No notifications", systemImage: "bell.slash")
                } else {
                    List(notifications) { note in
                        NotificationRowView(notification: note)
                            .listRowBackground(note.isRead ? Color.clear : Color("PlaciAccent").opacity(0.08))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notifications")
            .task { await load() }
        }
    }

    private func load() async {
        guard let userId = authManager.currentUserId else { return }
        isLoading = true
        defer { isLoading = false }
        notifications = (try? await NotificationService.fetchNotifications(userId: userId)) ?? []
        try? await NotificationService.markAllRead(userId: userId)
    }
}

private struct NotificationRowView: View {
    let notification: AppNotification

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: notification.actor?.avatarUrl, name: notification.actor?.displayName ?? "")
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(attributedText).font(.subheadline)
                Text(notification.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            notificationIcon
        }
        .padding(.vertical, 4)
    }

    private var attributedText: AttributedString {
        let actor = notification.actor?.displayName ?? "Someone"
        var str = AttributedString("\(actor) \(actionText)")
        if let range = str.range(of: actor) {
            str[range].font = .subheadline.bold()
        }
        return str
    }

    private var actionText: String {
        switch notification.type {
        case .like: return "liked your post."
        case .comment: return "commented on your post."
        case .follow: return "started following you."
        case .share: return "shared your post."
        }
    }

    private var notificationIcon: some View {
        Group {
            switch notification.type {
            case .like: Image(systemName: "heart.fill").foregroundStyle(.red)
            case .comment: Image(systemName: "bubble.right.fill").foregroundStyle(Color("PlaciAccent"))
            case .follow: Image(systemName: "person.fill.badge.plus").foregroundStyle(.green)
            case .share: Image(systemName: "arrowshape.turn.up.right.fill").foregroundStyle(.orange)
            }
        }
        .font(.subheadline)
    }
}
