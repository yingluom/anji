import Foundation
import SwiftUI

/// Applies the user's preferred language by writing to `AppleLanguages`.
///
/// Setting `AppleLanguages` only fully takes effect on next app launch. For a
/// same-session switch, we also bump `.locale` in the environment so that any
/// views reading `@Environment(\.locale)` re-render with the new strings.
///
/// Most view code reads localized strings via `Text("key")` which uses
/// `Bundle.main` directly, so a relaunch prompt is offered in Settings after
/// a language change.
enum LanguageManager {
    static let appleLanguagesKey = "AppleLanguages"

    /// Apply a preferred language setting at launch. No-op for `.system`.
    static func apply(_ preference: PreferredLanguage) {
        if let code = preference.appleLanguageCode {
            UserDefaults.standard.set([code], forKey: appleLanguagesKey)
        } else {
            UserDefaults.standard.removeObject(forKey: appleLanguagesKey)
        }
    }

    /// The effective locale to use for environment overrides.
    static func effectiveLocale(for preference: PreferredLanguage) -> Locale {
        if let code = preference.appleLanguageCode {
            return Locale(identifier: code)
        }
        return Locale.current
    }
}
