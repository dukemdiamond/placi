import SwiftUI

struct PlaciScoreBadge: View {
    let score: Double

    var body: some View {
        Text(String(format: "%.0f", score))
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch score {
        case 80...: return .green
        case 60..<80: return Color("PlaciAccent")
        case 40..<60: return .orange
        default: return .gray
        }
    }
}
