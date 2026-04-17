import SwiftUI
import AnkiBackend
import Dependencies
import Logging

/// Debug tools for developers and power users.
struct DebugView: View {
    @Dependency(\.ankiBackend) private var backend
    @Environment(\.dismiss) private var dismiss

    @State private var collectionPath = ""
    @State private var mediaPath = ""
    @State private var lastSync = "N/A"

    var body: some View {
        List {
            Section("debug.section.app") {
                LabeledContent("debug.version", value: appVersion)
                LabeledContent("debug.build", value: buildNumber)
                LabeledContent("debug.ios_version", value: UIDevice.current.systemVersion)
                LabeledContent("debug.device", value: UIDevice.current.model)
            }

            Section("debug.section.paths") {
                LabeledContent("debug.collection", value: collectionPath)
                    .lineLimit(1)
                    .truncationMode(.middle)
                LabeledContent("debug.media", value: mediaPath)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Section("debug.section.sync") {
                LabeledContent("debug.last_sync", value: lastSync)
            }

            Section("debug.section.actions") {
                Button("debug.check_db") {
                    try? backend.checkDatabase()
                }

                Button("debug.optimize_db") {
                    // Database optimization is handled automatically by Anki
                    // This button is kept for UI consistency
                }
                .disabled(true)

                Button("debug.clear_cache", role: .destructive) {
                    URLCache.shared.removeAllCachedResponses()
                }
            }

            Section {
                Button("common.done") { dismiss() }
            }
        }
        .navigationTitle("debug.title")
        .navigationBarTitleDisplayMode(.inline)
        .task { loadInfo() }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    private func loadInfo() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let ankiDir = appSupport.appendingPathComponent("AnjiCollection", isDirectory: true)
        collectionPath = ankiDir.appendingPathComponent("collection.anki2").path
        mediaPath = ankiDir.appendingPathComponent("media").path

        // TODO: Read last sync timestamp from shared settings if tracked
        lastSync = "N/A"
    }
}
