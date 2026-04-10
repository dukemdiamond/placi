import SwiftUI

struct PostSuccessView: View {
    let post: Post
    /// Called when user taps Done — should dismiss AddPlaceView entirely
    var onDone: () -> Void

    @State private var navigateToPost = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Success indicator
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color("PlaciAccent").opacity(0.12))
                            .frame(width: 100, height: 100)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color("PlaciAccent"))
                    }

                    Text("posted!")
                        .font(.custom("Nunito-Bold", size: 30))
                    Text(post.place?.name ?? post.title)
                        .font(.custom("Nunito-SemiBold", size: 18))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    NavigationLink(destination: PostDetailView(postId: post.id)) {
                        Label("View post", systemImage: "eye")
                            .font(.custom("Nunito-SemiBold", size: 17))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("PlaciAccent"))

                    ShareLink(
                        item: URL(string: "https://placi.app/post/\(post.id)")!,
                        subject: Text("Check out my place on placi"),
                        message: Text("I just logged \(post.place?.name ?? post.title) on placi 📍")
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.custom("Nunito-SemiBold", size: 17))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color("PlaciAccent"))

                    Button("Done") { onDone() }
                        .font(.custom("Nunito-Regular", size: 16))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
}
