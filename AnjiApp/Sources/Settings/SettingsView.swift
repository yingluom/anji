import SwiftUI
import Sharing

/// Top-level settings view — the fourth tab.
struct SettingsView: View {
    var body: some View {
        List {
            AppearanceSection()
            SyncSection()
            StorageSection()
            AdvancedSection()
            AboutSection()
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.anjiBackground)
        .navigationTitle("settings.title")
    }
}
