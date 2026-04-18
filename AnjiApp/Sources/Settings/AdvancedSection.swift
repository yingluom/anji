import SwiftUI
import Sharing

/// Advanced settings — sync options, Live Activity, etc.
/// Debug tools moved to About section with 8-tap unlock gesture.
struct AdvancedSection: View {
    @Shared(.autoSync) private var autoSync
    @Shared(.wifiOnlySync) private var wifiOnlySync
    @Shared(.liveActivityEnabled) private var liveActivityEnabled

    var body: some View {
        Section {
            Toggle(isOn: $autoSync) {
                Label("settings.auto_sync", systemImage: "arrow.clockwise.circle")
            }

            Toggle(isOn: $wifiOnlySync) {
                Label("settings.wifi_only", systemImage: "wifi")
            }

            if #available(iOS 16.1, *) {
                Toggle(isOn: $liveActivityEnabled) {
                    Label("settings.live_activity", systemImage: "island.2")
                }
            }
        } header: {
            Text("settings.section.advanced")
        } footer: {
            if #available(iOS 16.1, *) {
                Text("settings.advanced.footer.live_activity")
            } else {
                Text("Debug tools can be accessed by tapping the version number 8 times in About.")
            }
        }
    }
}
