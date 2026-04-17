import SwiftUI
import AnkiSync
import Sharing

/// First-run onboarding — defaults to AnkiWeb.
struct WelcomeView: View {
    @Shared(.onboardingDone) private var onboardingDone
    @Shared(.syncMode) private var syncMode
    @State private var showCustomServer = false
    @State private var serverURL = ""

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()

            Image(systemName: "book.pages.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.anjiAccent.gradient)
                .symbolEffect(.bounce, options: .nonRepeating)

            VStack(spacing: Spacing.sm) {
                Text("Anji")
                    .anjiFont(.largeTitle)
                    .foregroundStyle(Color.anjiPrimary)
                Text("Your Anki companion for iOS")
                    .anjiFont(.body)
                    .foregroundStyle(Color.anjiSecondary)
            }

            Spacer()

            if showCustomServer {
                customServerEntry
            } else {
                mainOptions
            }

            Text("You can change this later in sync settings")
                .anjiFont(.caption)
                .foregroundStyle(Color.anjiTertiary)
                .padding(.bottom, Spacing.xl)
        }
        .padding(.horizontal, Spacing.xxl)
        .background(Color.anjiBackground)
    }

    // MARK: - Main Options

    private var mainOptions: some View {
        VStack(spacing: Spacing.md) {
            Button {
                // Default to AnkiWeb — user will log in via SyncSheet
                try? KeychainHelper.saveEndpoint("https://sync.ankiweb.net")
                $syncMode.withLock { $0 = .ankiweb }
                $onboardingDone.withLock { $0 = true }
            } label: {
                Label("Sign in with AnkiWeb", systemImage: "globe")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AnjiPrimaryButton())

            Button {
                showCustomServer = true
            } label: {
                Label("Use Custom Server", systemImage: "server.rack")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AnjiSecondaryButton())

            Button {
                $syncMode.withLock { $0 = .local }
                $onboardingDone.withLock { $0 = true }
            } label: {
                Text("Use Offline Only")
                    .anjiFont(.callout)
                    .foregroundStyle(Color.anjiSecondary)
            }
        }
    }

    // MARK: - Custom Server Entry

    private var customServerEntry: some View {
        VStack(spacing: Spacing.md) {
            TextField("Server URL", text: $serverURL)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)

            Button("Continue") {
                var url = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
                if !url.hasPrefix("http://") && !url.hasPrefix("https://") {
                    url = "https://" + url
                }
                try? KeychainHelper.saveEndpoint(url)
                $syncMode.withLock { $0 = .custom }
                $onboardingDone.withLock { $0 = true }
            }
            .buttonStyle(AnjiPrimaryButton())
            .disabled(serverURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button("Back") { showCustomServer = false }
                .anjiFont(.callout)
                .foregroundStyle(Color.anjiSecondary)
        }
    }
}
