import SwiftUI

/// Advanced settings — debug tools.
struct AdvancedSection: View {
    var body: some View {
        Section {
            NavigationLink {
                DebugView()
            } label: {
                Label("settings.debug.title", systemImage: "ant")
            }
        } header: {
            Text("settings.section.advanced")
        }
    }
}
