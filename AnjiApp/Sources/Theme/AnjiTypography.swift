import SwiftUI

// MARK: - Typography Scale

enum AnjiFont {
    case largeTitle    // 32pt bold
    case title         // 22pt semibold
    case headline      // 18pt semibold
    case body          // 16pt regular
    case bodyBold      // 16pt semibold
    case callout       // 14pt regular
    case calloutBold   // 14pt semibold
    case footnote      // 13pt regular
    case caption       // 11pt regular

    var font: Font {
        switch self {
        case .largeTitle: .system(size: 32, weight: .bold, design: .rounded)
        case .title:      .system(size: 22, weight: .semibold, design: .rounded)
        case .headline:   .system(size: 18, weight: .semibold)
        case .body:       .system(size: 16, weight: .regular)
        case .bodyBold:   .system(size: 16, weight: .semibold)
        case .callout:    .system(size: 14, weight: .regular)
        case .calloutBold:.system(size: 14, weight: .semibold)
        case .footnote:   .system(size: 13, weight: .regular)
        case .caption:    .system(size: 11, weight: .regular)
        }
    }

    var tracking: CGFloat {
        switch self {
        case .largeTitle: -0.5
        case .title:      -0.3
        case .headline:   -0.2
        default:          0
        }
    }
}

extension View {
    func anjiFont(_ style: AnjiFont) -> some View {
        self.font(style.font).tracking(style.tracking)
    }
}
