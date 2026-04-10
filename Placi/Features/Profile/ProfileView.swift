import SwiftUI

struct ProfileView: View {
    let userId: UUID
    @State private var viewModel = ProfileViewModel()
    @Environment(AuthManager.self) private var authManager

    var isOwnProfile: Bool { userId == authManager.currentUserId }

    var body: some View {
        Group {
            if let profile = viewModel.profile {
                profileContent(profile)
            } else if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView("profile not found", systemImage: "person.slash")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.profile.map { "@\($0.username)" } ?? "")
        .toolbar {
            if isOwnProfile {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { SettingsView() } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color("PlaciAccent"))
                    }
                }
            }
        }
        .task { await viewModel.load(userId: userId, currentUserId: authManager.currentUserId) }
    }

    // MARK: - Main content

    @ViewBuilder
    private func profileContent(_ profile: Profile) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                header(profile)
                Divider().padding(.horizontal)
                tabs(profile)
            }
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(for: Post.self)    { PostDetailView(postId: $0.id) }
        .navigationDestination(for: Profile.self) { ProfileView(userId: $0.id) }
    }

    // MARK: - Header

    @ViewBuilder
    private func header(_ profile: Profile) -> some View {
        VStack(spacing: 16) {
            // Avatar
            AvatarView(url: profile.avatarUrl, name: profile.displayName)
                .frame(width: 96, height: 96)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)

            // Name + handle + bio
            VStack(spacing: 4) {
                Text(profile.displayName)
                    .font(.custom("Nunito-ExtraBold", size: 24))
                    .foregroundStyle(.primary)
                Text("@\(profile.username)")
                    .font(.custom("Nunito-Regular", size: 14))
                    .foregroundStyle(.secondary)
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.custom("Nunito-Regular", size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 2)
                }
            }

            // Stats — clickable
            HStack(spacing: 0) {
                NavigationLink {
                    beenList
                } label: {
                    statCell(value: viewModel.postCount, label: "places")
                }
                .buttonStyle(.plain)

                Divider().frame(height: 36)

                NavigationLink {
                    FollowerListView(userId: userId)
                } label: {
                    statCell(value: viewModel.followerCount, label: "followers")
                }
                .buttonStyle(.plain)

                Divider().frame(height: 36)

                NavigationLink {
                    FollowingListView(userId: userId)
                } label: {
                    statCell(value: viewModel.followingCount, label: "following")
                }
                .buttonStyle(.plain)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray5), lineWidth: 1))
            .padding(.horizontal, 24)

            // Action buttons
            if isOwnProfile {
                ownProfileButtons(profile)
            } else {
                followButton
            }
        }
        .padding(.bottom, 4)
    }

    private func statCell(value: Int, label: String) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.custom("Nunito-ExtraBold", size: 20))
                .foregroundStyle(.primary)
            Text(label)
                .font(.custom("Nunito-Regular", size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func ownProfileButtons(_ profile: Profile) -> some View {
        HStack(spacing: 10) {
            NavigationLink { SettingsView() } label: {
                Text("edit profile")
                    .font(.custom("Nunito-SemiBold", size: 14))
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            ShareLink(
                item: URL(string: "https://placi.app/profile/\(profile.username)")!,
                message: Text("check out @\(profile.username) on placi 📍")
            ) {
                Label("share profile", systemImage: "square.and.arrow.up")
                    .font(.custom("Nunito-SemiBold", size: 14))
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .background(Color("PlaciAccent"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 24)
    }

    private var followButton: some View {
        Button {
            Task { await viewModel.toggleFollow(currentUserId: authManager.currentUserId, targetId: userId) }
        } label: {
            Text(viewModel.isFollowing ? "following" : "follow")
                .font(.custom("Nunito-Bold", size: 16))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(viewModel.isFollowing ? Color(.systemGray5) : Color("PlaciAccent"))
                .foregroundStyle(viewModel.isFollowing ? Color.primary : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Tabs

    @ViewBuilder
    private func tabs(_ profile: Profile) -> some View {
        VStack(spacing: 0) {
            Picker("tab", selection: $viewModel.profileTab) {
                Text("been").tag(ProfileViewModel.ProfileTab.been)
                Text("want to go").tag(ProfileViewModel.ProfileTab.wantToGo)
                Text("ranked").tag(ProfileViewModel.ProfileTab.ranked)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            switch viewModel.profileTab {
            case .been:        beenList
            case .wantToGo:    wantToGoList
            case .ranked:
                RankedListView(posts: $viewModel.posts) { id, pos in
                    Task { await viewModel.reorder(postId: id, to: pos) }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private var beenList: some View {
        LazyVStack(spacing: 14) {
            if viewModel.posts.isEmpty {
                ContentUnavailableView(
                    "no places yet",
                    systemImage: "mappin.slash",
                    description: Text("places visited will appear here.")
                )
                .padding(.top, 40)
            } else {
                ForEach(viewModel.posts) { post in
                    NavigationLink(value: post) {
                        ProfilePostCard(post: post)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 24)
    }

    private var wantToGoList: some View {
        LazyVStack(spacing: 10) {
            if viewModel.bookmarkedPlaces.isEmpty {
                ContentUnavailableView(
                    "no bookmarks yet",
                    systemImage: "bookmark.slash",
                    description: Text("tap \"want to go\" on any place to save it here.")
                )
                .padding(.top, 40)
            } else {
                ForEach(viewModel.bookmarkedPlaces) { place in
                    WantToGoCard(place: place, userId: authManager.currentUserId)
                }
            }
        }
        .padding(.bottom, 24)
    }
}
