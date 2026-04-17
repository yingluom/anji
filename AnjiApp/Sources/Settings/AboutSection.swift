import SwiftUI

/// About settings — version, acknowledgments, open source.
struct AboutSection: View {
    @Environment(\.openURL) private var openURL

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        Section {
            HStack {
                Label("settings.about.version", systemImage: "info.circle")
                Spacer()
                Text("\(appVersion) (\(buildNumber))")
                    .font(.caption)
                    .foregroundStyle(Color.anjiSecondary)
            }

            Button {
                openURL(URL(string: "https://github.com/yingluom/anji")!)
            } label: {
                Label("settings.about.github", systemImage: "safari")
            }

            Button {
                openURL(URL(string: "https://apps.ankiweb.net")!)
            } label: {
                Label("settings.about.ankiweb", systemImage: "link")
            }
        } header: {
            Text("settings.section.about")
        } footer: {
            Text("settings.about.footer")
        }
    }
}
