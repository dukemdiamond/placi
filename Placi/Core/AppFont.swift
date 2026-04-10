import SwiftUI

/// Nunito font helpers — used when you need a specific weight explicitly.
/// The default `.font(.custom("Nunito-Regular", ...))` on the root view
/// handles most text automatically.
extension Font {
    static func nunito(size: CGFloat, weight: NunitoWeight = .regular) -> Font {
        .custom(weight.fontName, size: size)
    }

    static func nunitoRelative(_ style: Font.TextStyle, weight: NunitoWeight = .regular) -> Font {
        .custom(weight.fontName, relativeTo: style)
    }

    enum NunitoWeight {
        case light, regular, medium, semiBold, bold, extraBold

        var fontName: String {
            switch self {
            case .light:     return "Nunito-Light"
            case .regular:   return "Nunito-Regular"
            case .medium:    return "Nunito-Medium"
            case .semiBold:  return "Nunito-SemiBold"
            case .bold:      return "Nunito-Bold"
            case .extraBold: return "Nunito-ExtraBold"
            }
        }
    }
}
