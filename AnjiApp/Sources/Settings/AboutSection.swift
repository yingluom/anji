import SwiftUI

/// About settings — version, acknowledgments, open source.
/// Debug tools are hidden behind 8 consecutive taps on version number.
struct AboutSection: View {
    @Environment(\.openURL) private var openURL
    @AppStorage("debugUnlocked") private var debugUnlocked = false

    @State private var versionTapCount = 0
    @State private var lastTapTime = Date.distantPast
    @State private var showDebugUnlocked = false

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
                    .foregroundStyle(debugUnlocked ? Color.anjiSuccess : Color.anjiSecondary)
                    .contentTransition(.opacity)
                    .onTapGesture {
                        handleVersionTap()
                    }
                    .scaleEffect(showDebugUnlocked ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: showDebugUnlocked)
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

            // Debug entry - only visible when unlocked
            if debugUnlocked {
                NavigationLink {
                    DebugView()
                } label: {
                    Label("settings.debug.title", systemImage: "ant")
                        .foregroundStyle(Color.anjiSuccess)
                }
            }
        } header: {
            Text("settings.section.about")
        } footer: {
            Group {
                if debugUnlocked {
                    Text("Debug tools enabled. Tap version 8 more times to disable.")
                } else {
                    Text("settings.about.footer")
                }
            }
        }
    }

    private func handleVersionTap() {
        let now = Date()
        let timeSinceLastTap = now.timeIntervalSince(lastTapTime)

        // Reset if taps are too slow (> 1.5 seconds between taps)
        if timeSinceLastTap > 1.5 {
            versionTapCount = 0
        }

        versionTapCount += 1
        lastTapTime = now

        // Toggle debug mode on 8 consecutive taps
        if versionTapCount >= 8 {
            versionTapCount = 0
            debugUnlocked.toggle()

            withAnimation {
                showDebugUnlocked = true
            }

            // Reset animation state after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showDebugUnlocked = false
            }
        }
    }
}
