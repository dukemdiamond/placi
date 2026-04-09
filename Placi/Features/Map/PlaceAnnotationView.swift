import SwiftUI

struct PlaceAnnotationView: View {
    let post: Post

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(scoreColor(post.placiScore))
                    .frame(width: 36, height: 36)
                    .shadow(radius: 2)
                Text(String(format: "%.0f", post.placiScore))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            Triangle()
                .fill(scoreColor(post.placiScore))
                .frame(width: 10, height: 6)
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return Color("PlaciAccent")
        case 40..<60: return .orange
        default: return .gray
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
