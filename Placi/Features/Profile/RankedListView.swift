import SwiftUI

struct RankedListView: View {
    @Binding var posts: [Post]
    var onReorder: (UUID, Int) -> Void

    var body: some View {
        List {
            ForEach(Array(posts.enumerated()), id: \.element.id) { i, post in
                HStack(spacing: 12) {
                    Text("#\(i + 1)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.title).font(.subheadline.bold())
                        Text(post.place?.name ?? "").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    PlaciScoreBadge(score: post.placiScore)
                }
                .padding(.vertical, 4)
            }
            .onMove { source, destination in
                posts.move(fromOffsets: source, toOffset: destination)
                if let movedPost = posts[safe: destination > 0 ? destination - 1 : 0] {
                    onReorder(movedPost.id, destination)
                }
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
