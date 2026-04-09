import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int
    private let max = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Rating")
                Spacer()
                Text("\(rating) / \(max)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: Binding(
                get: { Double(rating) },
                set: { rating = Int($0.rounded()) }
            ), in: 1...Double(max), step: 1)
            .tint(Color("PlaciAccent"))
        }
    }
}
