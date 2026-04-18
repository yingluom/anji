import SwiftUI
import Sharing

/// Advanced settings — reserved for future options.
/// Debug tools moved to About section with 8-tap unlock gesture.
struct AdvancedSection: View {
    @Shared(.autoSync) private var autoSync
    @Shared(.wifiOnlySync) private var wifiOnlySync

    var body: some View {
        Section {
            Toggle(isOn: $autoSync) {
                Label("settings.auto_sync", systemImage: "arrow.clockwise.circle")
            }

            Toggle(isOn: $wifiOnlySync) {
                Label("settings.wifi_only", systemImage: "wifi")
            }
        } header: {
            Text("settings.section.advanced")
        } footer: {
            Text("Debug tools can be accessed by tapping the version number 8 times in About.")
        }
    }
}
