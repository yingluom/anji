import SwiftUI

// MARK: - Environment Key for Accent Color
private struct AnjiAccentKey: EnvironmentKey {
    static let defaultValue: Color = AccentPreset.indigo.color
}

extension EnvironmentValues {
    /// The current accent color for interactive elements.
    /// Set this at the root view via `.environment(\.anjiAccent, accentPreset.color)`
    var anjiAccent: Color {
        get { self[AnjiAccentKey.self] }
        set { self[AnjiAccentKey.self] = newValue }
    }
}

// MARK: - Anji Design System — Colors
// Neutrals are fixed; accent is driven by the user's AccentPreset choice and
// must be applied at the view layer via `.environment(\.anjiAccent, …)` or
// by reading `AccentPreset.current.color` from an `@Shared(.accentPreset)`.
//
// The static `Color.anjiAccent` now reads from the environment, so views must
// access it via `@Environment(\.anjiAccent) var anjiAccent`.

extension Color {
    // Backgrounds
    static let anjiBackground = Color(light: Color(hex: 0xF7F7FB), dark: Color(hex: 0x0A0A0F))
    static let anjiSurface    = Color(light: .white, dark: Color(hex: 0x161620))
    static let anjiElevated   = Color(light: .white, dark: Color(hex: 0x1E1E2C))

    // Text
    static let anjiPrimary    = Color(light: Color(hex: 0x12122A), dark: .white)
    static let anjiSecondary  = Color(light: .black.opacity(0.65), dark: .white.opacity(0.72))
    static let anjiTertiary   = Color(light: .black.opacity(0.38), dark: .white.opacity(0.42))

    // Legacy accent (deprecated - use @Environment(\.anjiAccent) instead).
    static let anjiAccent     = AccentPreset.indigo.color
    // Teal for secondary actions (kept stable regardless of accent)
    static let anjiTeal       = Color(light: Color(hex: 0x0D9488), dark: Color(hex: 0x2DD4BF))

    // Semantic
    static let anjiSuccess    = Color(light: Color(hex: 0x16A34A), dark: Color(hex: 0x4ADE80))
    static let anjiWarning    = Color(light: Color(hex: 0xEA580C), dark: Color(hex: 0xFB923C))
    static let anjiDanger     = Color(light: Color(hex: 0xDC2626), dark: Color(hex: 0xF87171))

    // Review buttons
    static let anjiAgain  = Color(hex: 0xEF4444)
    static let anjiHard   = Color(hex: 0xF59E0B)
    static let anjiGood   = Color(hex: 0x22C55E)
    static let anjiEasy   = Color(hex: 0x3B82F6)

    // Count badges
    static let anjiNew    = Color(hex: 0x3B82F6)
    static let anjiLearn  = Color(hex: 0xEF4444)
    static let anjiReview = Color(hex: 0x22C55E)
}

// MARK: - Helpers

extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
