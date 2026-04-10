import SwiftUI

struct ProfileView: View {
    let userId: UUID
    @State private var viewModel = ProfileViewModel()
    @Environment(AuthManager.self) private var authManager

    var isOwnProfile: Bool { userId == authManager.currentUserId }

    var body: some View {
        Group {
            if let profile = viewModel.profile {
                content(profile)
            } else if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView("profile not found", systemImage: "person.slash")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwnProfile {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink { NotificationsView() } label: {
                        Image(systemName: "bell")
                            .foregroundStyle(Color("PlaciAccent"))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        if let p = viewModel.profile { EditProfileView(profile: p) }
                    } label: {
                        Text("edit")
                            .font(.custom("Nunito-SemiBold", size: 15))
                    }
                }
            }
        }
        .task { await viewModel.load(userId: userId, currentUserId: authManager.currentUserId) }
    }

    @ViewBuilder
    private func content(_ profile: Profile) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                profileHeader(profile)

                // Tab picker
                Picker("tab", selection: $viewModel.profileTab) {
                    Text("been").tag(ProfileViewModel.ProfileTab.been)
                    Text("want to go").tag(ProfileViewModel.ProfileTab.wantToGo)
                    Text("ranked").tag(ProfileViewModel.ProfileTab.ranked)
                }
                .pickerStyle(.segmented)
                .font(.custom("Nunito-SemiBold", size: 13))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()

                switch viewModel.profileTab {
                case .been:
                    beenSection
                case .wantToGo:
                    wantToGoSection
                case .ranked:
                    RankedListView(posts: $viewModel.posts) { id, pos in
                        Task { await viewModel.reorder(postId: id, to: pos) }
                    }
                }
            }
        }
        .navigationDestination(for: Post.self) { post in PostDetailView(postId: post.id) }
        .navigationDestination(for: Profile.self) { p in ProfileView(userId: p.id) }
    }

    // MARK: - Header

    @ViewBuilder
    private func profileHeader(_ profile: Profile) -> some View {
        VStack(spacing: 16) {
            // Avatar
            AvatarView(url: profile.avatarUrl, name: profile.displayName)
                .frame(width: 90, height: 90)
                .shadow(radius: 4)

            // Name + username
            VStack(spacing: 4) {
                Text(profile.displayName)
                    .font(.custom("Nunito-ExtraBold", size: 22))
                Text("@\(profile.username)")
                    .font(.custom("Nunito-Regular", size: 14))
                    .foregroundStyle(.secondary)
                if let bio = profile.bio {
                    Text(bio)
                        .font(.custom("Nunito-Regular", size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 2)
                }
            }

            // Stats
            HStack(spacing: 0) {
                statItem(value: viewModel.postCount, label: "places")
                Divider().frame(height: 30)
                statItem(value: viewModel.followerCount, label: "followers")
                Divider().frame(height: 30)
                statItem(value: viewModel.followingCount, label: "following")
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 32)

            // Follow / Edit button
            if !isOwnProfile {
                Button {
                    Task { await viewModel.toggleFollow(currentUserId: authManager.currentUserId, targetId: userId) }
                } label: {
                    Text(viewModel.isFollowing ? "following" : "follow")
                        .font(.custom("Nunito-Bold", size: 15))
                        .frame(width: 160, height: 40)
                        .background(viewModel.isFollowing ? Color(.systemGray5) : Color("PlaciAccent"))
                        .foregroundStyle(viewModel.isFollowing ? .primary : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.custom("Nunito-ExtraBold", size: 18))
            Text(label)
                .font(.custom("Nunito-Regular", size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // MARK: - Been

    private var beenSection: some View {
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
        .padding(.top, 12)
        .padding(.bottom, 24)
    }

    // MARK: - Want to Go

    private var wantToGoSection: some View {
        LazyVStack(spacing: 12) {
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
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
}

// MARK: - Want to Go Card

struct WantToGoCard: View {
    let place: Place
    let userId: UUID?
    @State private var removed = false

    var body: some View {
        if !removed {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color("PlaciAccent").opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "mappin.fill")
                        .foregroundStyle(Color("PlaciAccent"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.custom("Nunito-Bold", size: 15))
                    if let address = place.address {
                        Text(address)
                            .font(.custom("Nunito-Regular", size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    guard let uid = userId else { return }
                    Task {
                        try? await BookmarkService.removeBookmark(userId: uid, placeId: place.id)
                        removed = true
                    }
                } label: {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(Color("PlaciAccent"))
                }
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 14)
        }
    }
}
