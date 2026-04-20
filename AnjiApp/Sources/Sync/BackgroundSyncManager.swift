import BackgroundTasks
import UIKit
import AnkiClients
import Dependencies
import Sharing
import AnkiSync

/// Manages background sync using BGTaskScheduler.
/// Register tasks in Info.plist: BGTaskSchedulerPermittedIdentifiers
@MainActor
final class BackgroundSyncManager {
    static let shared = BackgroundSyncManager()

    private let taskIdentifier = "com.anji.sync"
    @Dependency(\.syncClient) private var syncClient
    @Shared(.backgroundSyncEnabled) private var backgroundSyncEnabled
    @Shared(.wifiOnlySync) private var wifiOnlySync
    @Shared(.mediaSyncEnabled) private var mediaSyncEnabled
    @Shared(.lastSyncTime) private var lastSyncTime
    @Shared(.lastSyncStatus) private var lastSyncStatus

    private init() {}

    /// Register background tasks with the system.
    /// Call this in AppDelegate or AnjiApp.init.
    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { [weak self] task in
            Task { @MainActor in
                await self?.handleBackgroundSync(task: task as! BGAppRefreshTask)
            }
        }
    }

    /// Schedule the next background sync based on user preferences.
    func scheduleNextSync() {
        guard backgroundSyncEnabled,
              let interval = nextSyncInterval() else {
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background sync: \(error)")
        }
    }

    /// Cancel any pending background sync.
    func cancelPendingSync() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
    }

    /// Handle a background sync task.
    private func handleBackgroundSync(task: BGAppRefreshTask) async {
        // Schedule the next sync first
        scheduleNextSync()

        // Check if we should sync (Wi-Fi requirement)
        if wifiOnlySync {
            // Check network type - skip if not Wi-Fi
            // Note: This requires additional network monitoring
        }

        // Perform sync
        task.expirationHandler = {
            // Cleanup if needed
        }

        do {
            // Collection sync only (skip media in background to save battery)
            let summary = try await syncClient.sync()
            lastSyncTime = ISO8601DateFormatter().string(from: Date())
            lastSyncStatus = "success"

            // Only sync media if explicitly enabled and Wi-Fi
            if mediaSyncEnabled && !wifiOnlySync {
                _ = try? await syncClient.syncMedia()
            }

            task.setTaskCompleted(success: true)
        } catch {
            lastSyncTime = ISO8601DateFormatter().string(from: Date())
            lastSyncStatus = "failed"
            task.setTaskCompleted(success: false)
        }
    }

    /// Calculate the next sync interval based on user settings.
    private func nextSyncInterval() -> TimeInterval? {
        @Shared(.syncIntervalMinutes) var syncIntervalMinutes: Int

        let minutes = syncIntervalMinutes
        guard minutes > 0 else { return nil }

        return TimeInterval(minutes * 60)
    }
}
