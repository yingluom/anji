import SwiftUI
import AnkiBackend
import AnkiSync
import Dependencies
import Sharing

@main
struct AnjiApp: App {
    @Shared(.onboardingDone) private var onboardingDone
    @Shared(.preferredLanguage) private var preferredLanguage
    @Shared(.appTheme) private var appTheme
    @Shared(.accentPreset) private var accentPreset

    @State private var pendingReviewDeckId: Int64? = nil

    init() {
        // Apply language preference immediately (requires relaunch to fully take effect).
        LanguageManager.apply(preferredLanguage)
        try! prepareDependencies {
            let backend = try AnkiBackend(preferredLanguages: ["en"])

            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first!
            let ankiDir = appSupport.appendingPathComponent("AnjiCollection", isDirectory: true)
            try FileManager.default.createDirectory(at: ankiDir, withIntermediateDirectories: true)

            let collectionPath = ankiDir.appendingPathComponent("collection.anki2").path
            let mediaPath      = ankiDir.appendingPathComponent("media").path
            let mediaDbPath    = ankiDir.appendingPathComponent("media.db").path
            try FileManager.default.createDirectory(
                atPath: mediaPath, withIntermediateDirectories: true
            )

            try backend.openCollection(
                collectionPath: collectionPath,
                mediaFolderPath: mediaPath,
                mediaDbPath: mediaDbPath
            )
            try? backend.checkDatabase()
            $0.ankiBackend = backend
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingDone {
                    MainTabView(pendingReviewDeckId: $pendingReviewDeckId)
                } else {
                    WelcomeView()
                }
            }
            .preferredColorScheme(appTheme.colorScheme)
            .tint(accentPreset.color)
            .environment(\.locale, LanguageManager.effectiveLocale(for: preferredLanguage))
            .onOpenURL { url in
                guard url.scheme == "anji", url.host == "review",
                      let deckIdStr = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                          .queryItems?.first(where: { $0.name == "deckId" })?.value,
                      let deckId = Int64(deckIdStr) else { return }
                pendingReviewDeckId = deckId
            }
        }
    }
}
