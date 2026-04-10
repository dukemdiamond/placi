import SwiftUI

struct PlaciScoreBadge: View {
    let score: Double   // 1.0–10.0

    var body: some View {
        Text(String(format: "%.1f", score))
            .font(.custom("Nunito-Bold", size: 13))
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch score {
        case 7.0...:    return Color("PlaciAccent")
        case 4.0..<7.0: return .orange
        default:        return Color(.systemGray3)
        }
    }
}
