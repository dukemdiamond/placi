import SwiftUI

private extension Font.TextStyle {
    /// Approximate point size that matches each SwiftUI text style at default Dynamic Type size.
    var defaultSize: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title:      return 28
        case .title2:     return 22
        case .title3:     return 20
        case .headline:   return 17
        case .body:       return 17
        case .callout:    return 16
        case .subheadline:return 15
        case .footnote:   return 13
        case .caption:    return 12
        case .caption2:   return 11
        @unknown default: return 17
        }
    }
}

/// Nunito font helpers — used when you need a specific weight explicitly.
/// The default `.font(.custom("Nunito-Regular", ...))` on the root view
/// handles most text automatically.
extension Font {
    static func nunito(size: CGFloat, weight: NunitoWeight = .regular) -> Font {
        .custom(weight.fontName, size: size)
    }

    static func nunitoRelative(_ style: Font.TextStyle, weight: NunitoWeight = .regular) -> Font {
        .custom(weight.fontName, size: style.defaultSize, relativeTo: style)
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
