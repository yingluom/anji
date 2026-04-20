import SwiftUI
import Sharing
import AnkiSync

/// Sync settings — server, account, auto-sync, media, scheduled sync, background sync.
struct SyncSection: View {
    @Shared(.syncMode) private var syncMode
    @Shared(.autoSync) private var autoSync
    @Shared(.wifiOnlySync) private var wifiOnlySync
    @Shared(.mediaSyncEnabled) private var mediaSyncEnabled
    @Shared(.syncIntervalMinutes) private var syncIntervalMinutes
    @Shared(.backgroundSyncEnabled) private var backgroundSyncEnabled
    @Shared(.lastSyncTime) private var lastSyncTime
    @Shared(.lastSyncStatus) private var lastSyncStatus

    @State private var showSyncSheet = false

    var body: some View {
        Section {
            // Sync Now button with user info
            Button {
                showSyncSheet = true
            } label: {
                HStack {
                    Label("settings.sync.now", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if let user = KeychainHelper.loadUsername() {
                            Text(user)
                                .font(.caption)
                                .foregroundStyle(Color.anjiSecondary)
                        }
                        if !lastSyncTime.isEmpty {
                            Text("Last: \(formattedLastSync)")
                                .font(.caption2)
                                .foregroundStyle(lastSyncStatusColor)
                        }
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.anjiTertiary)
                }
            }
            .sheet(isPresented: $showSyncSheet) {
                SyncSheet(isPresented: $showSyncSheet)
            }

            // Auto sync toggle
            Toggle(isOn: Binding($autoSync)) {
                Label("settings.auto_sync", systemImage: "arrow.clockwise.circle")
            }

            // Sync interval picker (only when auto sync is on)
            if autoSync {
                Picker(selection: $syncIntervalMinutes) {
                    Text("Manual only").tag(0)
                    Text("Every 15 min").tag(15)
                    Text("Every 30 min").tag(30)
                    Text("Every hour").tag(60)
                    Text("Every 6 hours").tag(360)
                    Text("Daily").tag(1440)
                } label: {
                    Label("settings.sync_interval", systemImage: "timer")
                }
            }

            // Background sync toggle
            Toggle(isOn: Binding($backgroundSyncEnabled)) {
                Label("settings.background_sync", systemImage: "moon.fill")
            }

            Toggle(isOn: Binding($wifiOnlySync)) {
                Label("settings.wifi_only", systemImage: "wifi")
            }

            Toggle(isOn: Binding($mediaSyncEnabled)) {
                Label("settings.media_sync", systemImage: "photo.on.rectangle.angled")
            }
        } header: {
            Text("settings.section.sync")
        } footer: {
            if backgroundSyncEnabled {
                Text("settings.background_sync.footer")
            } else if syncIntervalMinutes > 0 {
                Text("settings.sync_interval.footer")
            } else {
                Text("settings.media_sync.footer")
            }
        }
    }

    private var formattedLastSync: String {
        guard !lastSyncTime.isEmpty,
              let date = ISO8601DateFormatter().date(from: lastSyncTime) else {
            return "Never"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var lastSyncStatusColor: Color {
        switch lastSyncStatus {
        case "success": return .anjiSuccess
        case "failed": return .anjiWarning
        case "inProgress": return .anjiAccent
        default: return .anjiSecondary
        }
    }
}
