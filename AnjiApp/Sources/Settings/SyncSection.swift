import SwiftUI
import Sharing

/// Sync settings — server, account, auto-sync, media.
struct SyncSection: View {
    @Shared(.syncMode) private var syncMode
    @Shared(.autoSync) private var autoSync
    @Shared(.wifiOnlySync) private var wifiOnlySync
    @Shared(.mediaSyncEnabled) private var mediaSyncEnabled

    @State private var showSyncSheet = false

    var body: some View {
        Section {
            Button {
                showSyncSheet = true
            } label: {
                HStack {
                    Label("settings.sync.now", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    if let user = KeychainHelper.loadUsername() {
                        Text(user)
                            .font(.caption)
                            .foregroundStyle(Color.anjiSecondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.anjiTertiary)
                }
            }
            .sheet(isPresented: $showSyncSheet) {
                SyncSheet(isPresented: $showSyncSheet)
            }

            Toggle(isOn: $autoSync) {
                Label("settings.auto_sync", systemImage: "arrow.clockwise.circle")
            }

            Toggle(isOn: $wifiOnlySync) {
                Label("settings.wifi_only", systemImage: "wifi")
            }

            Toggle(isOn: $mediaSyncEnabled) {
                Label("settings.media_sync", systemImage: "photo.on.rectangle.angled")
            }
        } header: {
            Text("settings.section.sync")
        } footer: {
            Text("settings.media_sync.footer")
        }
    }
}
