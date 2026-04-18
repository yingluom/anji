import SwiftUI

// MARK: - Spacing tokens

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Card container

struct AnjiCardStyle: ViewModifier {
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(elevated ? Color.anjiElevated : Color.anjiSurface)
            )
            .if(elevated) { $0.shadow(color: .black.opacity(0.12), radius: 12, y: 4) }
    }
}

extension View {
    func anjiCard(elevated: Bool = false) -> some View {
        modifier(AnjiCardStyle(elevated: elevated))
    }

    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Primary button

struct AnjiPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .anjiFont(.bodyBold)
            .foregroundStyle(.white)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.xl)
            .background(Color.accentColor, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AnjiSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .anjiFont(.bodyBold)
            .foregroundStyle(Color.accentColor)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.xl)
            .background(
                Capsule().stroke(Color.accentColor, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
