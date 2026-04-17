import AnkiKit
import AnkiServices
import AnkiSync
public import Dependencies
import DependenciesMacros
import Logging

private let log = Logger(label: "anji.sync.client")

extension SyncClient: DependencyKey {
    public static let liveValue: Self = {
        @Dependency(\.syncService) var syncService

        return Self(
            sync: {
                guard let hostKey = KeychainHelper.loadHostKey(), !hostKey.isEmpty else {
                    throw SyncError.authFailed
                }
                let endpoint = KeychainHelper.loadEndpoint() ?? ankiWebEndpoint
                log.info("Starting collection sync with \(endpoint)")
                return try await syncService.syncCollection(endpoint, hostKey)
            },
            fullSync: { direction in
                guard let hostKey = KeychainHelper.loadHostKey(), !hostKey.isEmpty else {
                    throw SyncError.authFailed
                }
                let endpoint = KeychainHelper.loadEndpoint() ?? ankiWebEndpoint
                try await syncService.fullSync(endpoint, hostKey, direction)
            },
            syncMedia: {
                guard let hostKey = KeychainHelper.loadHostKey(), !hostKey.isEmpty else {
                    throw SyncError.authFailed
                }
                let endpoint = KeychainHelper.loadEndpoint() ?? ankiWebEndpoint
                try await syncService.syncMedia(endpoint, hostKey)
                return MediaSyncSummary()
            },
            syncMediaWithProgress: { onProgress in
                guard let hostKey = KeychainHelper.loadHostKey(), !hostKey.isEmpty else {
                    throw SyncError.authFailed
                }
                let endpoint = KeychainHelper.loadEndpoint() ?? ankiWebEndpoint
                return try await syncService.syncMediaWithProgress(endpoint, hostKey, onProgress)
            }
        )
    }()

    /// Authenticate with the sync server and store the returned credentials.
    public static func login(
        username: String,
        password: String
    ) async throws -> String {
        @Dependency(\.syncService) var syncService
        let endpoint = KeychainHelper.loadEndpoint() ?? ankiWebEndpoint
        log.info("Logging in as \(username) to \(endpoint)")
        let hostKey = try await syncService.login(endpoint, username, password)
        try KeychainHelper.saveHostKey(hostKey)
        try KeychainHelper.saveUsername(username)
        return hostKey
    }
}
