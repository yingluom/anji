import Foundation
import Sharing
import SwiftUI

// MARK: - Preference Types

/// User-visible appearance preference — light/dark/system.
enum AppTheme: String, CaseIterable, Sendable, Codable {
    case system, light, dark

    var titleKey: LocalizedStringKey {
        switch self {
        case .system: "theme.system"
        case .light:  "theme.light"
        case .dark:   "theme.dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}

/// Accent color preset — seven curated choices.
enum AccentPreset: String, CaseIterable, Sendable, Codable {
    case indigo  // default — matches legacy
    case orange, green, blue, purple, pink, teal, black

    var titleKey: LocalizedStringKey {
        switch self {
        case .indigo: "accent.indigo"
        case .orange: "accent.orange"
        case .green:  "accent.green"
        case .blue:   "accent.blue"
        case .purple: "accent.purple"
        case .pink:   "accent.pink"
        case .teal:   "accent.teal"
        case .black:  "accent.black"
        }
    }

    /// Hex values used for both light + dark (will be wrapped with Color(light:dark:) at the use site).
    var hex: (light: UInt, dark: UInt) {
        switch self {
        case .indigo: (0x4F46E5, 0x818CF8)
        case .orange: (0xFF9500, 0xFFB74D)
        case .green:  (0x34C759, 0x30D158)
        case .blue:   (0x007AFF, 0x0A84FF)
        case .purple: (0xAF52DE, 0xBF5AF2)
        case .pink:   (0xFF2D55, 0xFF375F)
        case .teal:   (0x5AC8FA, 0x64D2FF)
        case .black:  (0x000000, 0xFFFFFF)  // Pure black in light, white in dark for contrast
        }
    }

    var color: Color {
        Color(light: Color(hex: hex.light), dark: Color(hex: hex.dark))
    }
}

/// Preferred language: `system` follows iOS, others override.
enum PreferredLanguage: String, CaseIterable, Sendable, Codable {
    case system
    case en
    case zhHans = "zh-Hans"

    var titleKey: LocalizedStringKey {
        switch self {
        case .system: "lang.system"
        case .en:     "lang.english"
        case .zhHans: "lang.chinese_simplified"
        }
    }

    /// The BCP-47 code to write to AppleLanguages, or nil to remove override.
    var appleLanguageCode: String? {
        switch self {
        case .system: nil
        case .en:     "en"
        case .zhHans: "zh-Hans"
        }
    }
}

// MARK: - Onboarding / Sync mode (moved from SharedKeys.swift)

enum SyncMode: String, Sendable, Codable {
    case ankiweb
    case custom
    case local
}

// MARK: - @Shared keys — all persisted user preferences in one place

extension SharedReaderKey where Self == AppStorageKey<Bool>.Default {
    /// Whether the first-run welcome flow has been completed.
    static var onboardingDone: Self {
        Self[.appStorage("onboardingDone"), default: false]
    }

    /// Whether collection sync should run automatically on app foreground.
    static var autoSync: Self {
        Self[.appStorage("autoSync"), default: true]
    }

    /// Restrict syncs to Wi-Fi only.
    static var wifiOnlySync: Self {
        Self[.appStorage("wifiOnlySync"), default: false]
    }

    /// Include media files when syncing (large download).
    static var mediaSyncEnabled: Self {
        Self[.appStorage("mediaSyncEnabled"), default: true]
    }

    /// Enable Live Activity / Dynamic Island support during study.
    static var liveActivityEnabled: Self {
        Self[.appStorage("liveActivityEnabled"), default: true]
    }
}

extension SharedReaderKey where Self == AppStorageKey<SyncMode>.Default {
    static var syncMode: Self {
        Self[.appStorage("syncMode"), default: .ankiweb]
    }
}

extension SharedReaderKey where Self == AppStorageKey<AppTheme>.Default {
    static var appTheme: Self {
        Self[.appStorage("appTheme"), default: .system]
    }
}

extension SharedReaderKey where Self == AppStorageKey<AccentPreset>.Default {
    static var accentPreset: Self {
        Self[.appStorage("accentPreset"), default: .indigo]
    }
}

extension SharedReaderKey where Self == AppStorageKey<PreferredLanguage>.Default {
    static var preferredLanguage: Self {
        Self[.appStorage("preferredLanguage"), default: .system]
    }
}
