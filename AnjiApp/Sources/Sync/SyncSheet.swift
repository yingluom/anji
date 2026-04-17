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
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header with main progress
                    VStack(spacing: Spacing.sm) {
                        ProgressView()
                            .controlSize(.large)
                        Text(msg)
                            .anjiFont(.body)
                            .foregroundStyle(Color.anjiSecondary)
                    }
                    
                    // Collection sync stats card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "rectangle.stack")
                                .foregroundStyle(Color.anjiAccent)
                            Text("Collection Sync")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.anjiSuccess)
                                .opacity(msg.contains("media") ? 1 : 0)
                        }
                        
                        Divider()
                        
                        HStack(spacing: 16) {
                            StatItem(icon: "arrow.down.circle.fill", value: "Done", label: "Download", color: .blue)
                            StatItem(icon: "arrow.up.circle.fill", value: "Done", label: "Upload", color: .green)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.anjiCardBackground)
                    )
                    .padding(.horizontal)
                    
                    // Media sync progress card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundStyle(Color.purple)
                            Text("Media Sync")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            if isMediaSyncActive {
                                Text(formatOperation(mediaProgress.currentOperation))
                                    .font(.caption)
                                    .foregroundStyle(Color.anjiAccent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.anjiAccent.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        if isMediaSyncActive {
                            Divider()
                            
                            // Progress bar
                            VStack(alignment: .leading, spacing: 8) {
                                ProgressView(value: mediaProgress.progress)
                                    .tint(Color.purple)
                                
                                HStack {
                                    Text("\(mediaProgress.checked + mediaProgress.downloaded + mediaProgress.uploaded) / \(mediaProgress.totalFiles) files")
                                        .font(.caption)
                                        .foregroundStyle(Color.anjiSecondary)
                                    Spacer()
                                    Text("\(Int(mediaProgress.progress * 100))%")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color.anjiAccent)
                                }
                            }
                            
                            // Stats grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                MediaStatItem(
                                    icon: "arrow.down.circle.fill",
                                    count: mediaProgress.downloaded,
                                    label: "Downloaded",
                                    color: .blue
                                )
                                MediaStatItem(
                                    icon: "arrow.up.circle.fill",
                                    count: mediaProgress.uploaded,
                                    label: "Uploaded",
                                    color: .green
                                )
                                MediaStatItem(
                                    icon: "trash.circle.fill",
                                    count: mediaProgress.removed,
                                    label: "Removed",
                                    color: .red
                                )
                            }
                            
                            // Current file
                            if !mediaProgress.currentFile.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "doc.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.anjiTertiary)
                                    Text(mediaProgress.currentFile)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .foregroundStyle(Color.anjiSecondary)
                                    Spacer()
                                }
                                .padding(8)
                                .background(Color.anjiBackground)
                                .cornerRadius(8)
                            }
                        } else {
                            Label("Waiting for collection sync...", systemImage: "hourglass")
                                .font(.caption)
                                .foregroundStyle(Color.anjiTertiary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.anjiCardBackground)
                    )
                    .padding(.horizontal)
                    
                    // Sync logs card
                    if !syncLogs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(Color.gray)
                                Text("Sync Log")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(syncLogs.count) entries")
                                    .font(.caption2)
                                    .foregroundStyle(Color.anjiTertiary)
                            }
                            
                            Divider()
                            
                            ScrollView(.vertical, showsIndicators: true) {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(Array(syncLogs.enumerated()), id: \.offset) { index, log in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("\(index + 1)")
                                                .font(.caption2)
                                                .foregroundStyle(Color.anjiTertiary)
                                                .frame(width: 24, alignment: .leading)
                                            Text(log)
                                                .font(.caption)
                                                .foregroundStyle(Color.anjiSecondary)
                                                .lineLimit(2)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.anjiCardBackground)
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
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
}

// MARK: - Stat Item Views

private struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.anjiPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.anjiSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.anjiPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.anjiSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MediaStatItem: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text("\(count)")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.anjiPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.anjiSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Main View Continuation

extension SyncSheet {
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
