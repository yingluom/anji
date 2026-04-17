import SwiftUI
import AnkiKit
import AnkiClients
import AnkiSync
import Dependencies

struct SyncSheet: View {
    @Binding var isPresented: Bool
    @Dependency(\.syncClient) var syncClient
    @State private var state: SyncState = .idle
    @State private var showLogin = false
    @State private var syncLogs: [String] = []
    @State private var mediaProgress: AnkiKit.MediaSyncProgress = .init()
    @State private var isMediaSyncActive = false

    enum SyncState {
        case idle, syncing(String), success(SyncSummary), error(String), needsFullSync
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                if let endpoint = KeychainHelper.loadEndpoint() {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Server").font(.caption).foregroundStyle(.secondary)
                            Text(endpoint).font(.caption2).foregroundStyle(.tertiary)
                                .lineLimit(1).truncationMode(.middle)
                            if let user = KeychainHelper.loadUsername() {
                                Text(user).font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        Button("Logout", role: .destructive) { logout() }
                            .font(.caption)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }

                Spacer()
                stateView
                Spacer()
            }
            .navigationTitle("Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginSheet(isPresented: $showLogin) {
                Task { await startSync() }
            }
        }
        .task { await startSync() }
    }

    // MARK: - State Views

    @ViewBuilder
    private var stateView: some View {
        switch state {
        case .idle:
            ProgressView("Preparing…")
        case .syncing(let msg):
            VStack(spacing: Spacing.md) {
                ProgressView()
                    .controlSize(.large)
                Text(msg)
                    .anjiFont(.body)
                    .foregroundStyle(Color.anjiSecondary)
                
                // Media sync progress
                if isMediaSyncActive {
                    VStack(spacing: Spacing.sm) {
                        ProgressView(value: Double(mediaProgress.downloaded + mediaProgress.uploaded), 
                                   total: Double(max(mediaProgress.downloaded + mediaProgress.uploaded + 1, 10)))
                        HStack(spacing: Spacing.sm) {
                            Label("\(mediaProgress.downloaded)", systemImage: "arrow.down.circle")
                            Label("\(mediaProgress.uploaded)", systemImage: "arrow.up.circle")
                            Label("\(mediaProgress.removed)", systemImage: "trash")
                        }
                        .font(.caption)
                        .foregroundStyle(Color.anjiTertiary)
                        if !mediaProgress.currentFile.isEmpty {
                            Text(mediaProgress.currentFile)
                                .font(.caption2)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundStyle(Color.anjiSecondary)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Sync logs
                if !syncLogs.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(syncLogs.suffix(5), id: \.self) { log in
                                Text(log)
                                    .font(.caption2)
                                    .foregroundStyle(Color.anjiTertiary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .frame(height: 80)
                    .padding(.horizontal)
                }
            }
        case .success(let summary):
            VStack(spacing: Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.anjiSuccess)
                Text("Sync Complete")
                    .anjiFont(.headline)
                if summary.isUpToDate {
                    Text("Everything is up to date")
                        .anjiFont(.callout).foregroundStyle(Color.anjiSecondary)
                }
            }
        case .error(let msg):
            VStack(spacing: Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.anjiWarning)
                Text("Sync Failed").anjiFont(.headline)
                Text(msg).anjiFont(.callout).foregroundStyle(Color.anjiSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
                Button("Retry") { Task { await startSync() } }
                    .buttonStyle(.borderedProminent).tint(.anjiAccent)
            }
        case .needsFullSync:
            fullSyncView
        }
    }

    private var fullSyncView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48)).foregroundStyle(Color.anjiWarning)
            Text("Full Sync Required").anjiFont(.headline)
            Text("Choose which version to keep.")
                .anjiFont(.callout).foregroundStyle(Color.anjiSecondary)

            VStack(spacing: Spacing.sm) {
                Button { Task { await fullSync(.download) } } label: {
                    Label("Download from Server", systemImage: "arrow.down.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(.anjiAccent)

                Button { Task { await fullSync(.upload) } } label: {
                    Label("Upload to Server", systemImage: "arrow.up.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func startSync() async {
        guard KeychainHelper.loadEndpoint() != nil else {
            showLogin = true; return
        }
        guard KeychainHelper.loadHostKey() != nil else {
            showLogin = true; return
        }
        
        syncLogs.removeAll()
        mediaProgress = .init()

        state = .syncing("Syncing collection…")
        addLog("Connecting to AnkiWeb...")
        
        do {
            let summary = try await syncClient.sync()
            addLog("Collection sync complete")
            
            state = .syncing("Syncing media…")
            isMediaSyncActive = true
            mediaProgress = AnkiKit.MediaSyncProgress(currentOperation: .checking)
            addLog("Starting media sync...")
            
            do {
                // Use the new progress-based API
                let mediaSummary = try await syncClient.syncMediaWithProgress { progress in
                    // Update UI on main thread
                    DispatchQueue.main.async {
                        mediaProgress = progress
                        // Log significant progress changes
                        if progress.currentOperation == .downloading && progress.checked > 0 {
                            addLog("Checking: \(progress.checked) files...")
                        }
                        if !progress.currentFile.isEmpty {
                            addLog("\(progress.currentOperation): \(progress.currentFile)")
                        }
                    }
                }
                addLog("Media sync complete: \(mediaSummary.downloaded) downloaded, \(mediaSummary.uploaded) uploaded, \(mediaSummary.removed) removed")
            } catch {
                addLog("Media sync failed: \(error.localizedDescription)")
                // Don't fail entire sync if media fails
            }
            isMediaSyncActive = false
            
            state = .success(summary)
        } catch let e as SyncError where e == .authFailed {
            showLogin = true; state = .idle
        } catch let e as SyncError where e == .fullSyncRequired {
            state = .needsFullSync
        } catch {
            addLog("Sync failed: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        }
    }
    
    private func addLog(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        syncLogs.append("[\(timestamp.prefix(19))] \(message)")
    }
    
    private func formatOperation(_ op: MediaSyncOperation) -> String {
        switch op {
        case .checking: return "Checking"
        case .downloading: return "Downloading"
        case .uploading: return "Uploading"
        case .removing: return "Removing"
        case .complete: return "Complete"
        }
    }

    private func fullSync(_ direction: SyncDirection) async {
        state = .syncing(direction == .download ? "Downloading…" : "Uploading…")
        do {
            try await syncClient.fullSync(direction)
            state = .success(SyncSummary())
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func logout() {
        KeychainHelper.deleteHostKey()
        KeychainHelper.deleteUsername()
        state = .idle
    }
}
