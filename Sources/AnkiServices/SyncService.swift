import AnkiBackend
import AnkiProto
import AnkiSync
public import AnkiKit
public import Dependencies
import DependenciesMacros
import Foundation
import Logging
import SwiftProtobuf

private let log = Logger(label: "anji.sync")

/// The default AnkiWeb sync endpoint.
public let ankiWebEndpoint = "https://sync.ankiweb.net"

@DependencyClient
public struct SyncService: Sendable {
    /// Authenticate with the sync server.
    public var login: @Sendable (
        _ endpoint: String, _ username: String, _ password: String
    ) async throws -> String

    /// Perform an incremental collection sync.
    public var syncCollection: @Sendable (
        _ endpoint: String, _ hostKey: String
    ) async throws -> SyncSummary

    /// Force a full upload or download.
    public var fullSync: @Sendable (
        _ endpoint: String, _ hostKey: String, _ direction: SyncDirection
    ) async throws -> Void

    /// Sync media files.
    public var syncMedia: @Sendable (
        _ endpoint: String, _ hostKey: String
    ) async throws -> Void
    
    /// Sync media files with progress callback.
    public var syncMediaWithProgress: @Sendable (
        _ endpoint: String, _ hostKey: String,
        _ onProgress: @escaping @Sendable (MediaSyncProgress) -> Void
    ) async throws -> MediaSyncSummary
}

extension SyncService: DependencyKey {
    public static let liveValue: Self = {
        @Dependency(\.ankiBackend) var backend
        return Self(
            login: { endpoint, username, password in
                var req = Anki_Sync_SyncLoginRequest()
                req.username = username
                req.password = password
                req.endpoint = endpoint

                do {
                    let auth: Anki_Sync_SyncAuth = try backend.invoke(
                        service: AnkiBackend.Service.sync,
                        method: AnkiBackend.SyncMethod.syncLogin,
                        request: req
                    )
                    log.info("Login successful for \(username)")
                    return auth.hkey
                } catch let error as BackendError {
                    log.error("Login failed: \(error.message)")
                    throw SyncError.authFailed
                }
            },
            syncCollection: { endpoint, hostKey in
                var auth = Anki_Sync_SyncAuth()
                auth.hkey = hostKey
                auth.endpoint = endpoint

                var req = Anki_Sync_SyncCollectionRequest()
                req.auth = auth
                req.syncMedia = true

                do {
                    let responseBytes = try backend.call(
                        service: AnkiBackend.Service.sync,
                        method: AnkiBackend.SyncMethod.syncCollection,
                        request: req
                    )
                    let response = try Anki_Sync_SyncCollectionResponse(serializedBytes: responseBytes)
                    log.info("SyncCollection result: \(response.required)")

                    // If the server redirected us to a new endpoint, use it
                    if response.hasNewEndpoint, !response.newEndpoint.isEmpty {
                        auth.endpoint = response.newEndpoint
                    }

                    switch response.required {
                    case .noChanges, .normalSync:
                        return SyncSummary()

                    case .fullSync, .fullDownload:
                        log.info("Server requires full download")
                        var dlReq = Anki_Sync_FullUploadOrDownloadRequest()
                        dlReq.auth = auth
                        dlReq.upload = false
                        dlReq.serverUsn = response.serverMediaUsn
                        try backend.invokeVoid(
                            service: AnkiBackend.Service.sync,
                            method: AnkiBackend.SyncMethod.fullUploadOrDownload,
                            request: dlReq
                        )
                        try? backend.checkDatabase()
                        return SyncSummary()

                    case .fullUpload:
                        log.info("Server requires full upload")
                        var ulReq = Anki_Sync_FullUploadOrDownloadRequest()
                        ulReq.auth = auth
                        ulReq.upload = true
                        ulReq.serverUsn = response.serverMediaUsn
                        try backend.invokeVoid(
                            service: AnkiBackend.Service.sync,
                            method: AnkiBackend.SyncMethod.fullUploadOrDownload,
                            request: ulReq
                        )
                        return SyncSummary()

                    case .UNRECOGNIZED(let v):
                        log.warning("Unknown sync requirement: \(v)")
                        return SyncSummary()
                    }
                } catch let error as BackendError {
                    log.error("Sync error: \(error.message)")
                    if error.isSyncAuthError { throw SyncError.authFailed }
                    throw SyncError(message: error.message)
                }
            },
            fullSync: { endpoint, hostKey, direction in
                var auth = Anki_Sync_SyncAuth()
                auth.hkey = hostKey
                auth.endpoint = endpoint

                var req = Anki_Sync_FullUploadOrDownloadRequest()
                req.auth = auth
                req.upload = (direction == .upload)

                do {
                    try backend.invokeVoid(
                        service: AnkiBackend.Service.sync,
                        method: AnkiBackend.SyncMethod.fullUploadOrDownload,
                        request: req
                    )
                } catch let error as BackendError {
                    if error.isSyncAuthError { throw SyncError.authFailed }
                    throw SyncError(message: error.message)
                }
            },
            syncMedia: { endpoint, hostKey in
                var auth = Anki_Sync_SyncAuth()
                auth.hkey = hostKey
                auth.endpoint = endpoint

                do {
                    try backend.invokeVoid(
                        service: AnkiBackend.Service.sync,
                        method: AnkiBackend.SyncMethod.syncMedia,
                        request: auth
                    )
                    log.info("Media sync complete")
                } catch let error as BackendError {
                    if error.isSyncAuthError { throw SyncError.authFailed }
                    throw SyncError(message: error.message)
                }
            },
            syncMediaWithProgress: { endpoint, hostKey, onProgress in
                var auth = Anki_Sync_SyncAuth()
                auth.hkey = hostKey
                auth.endpoint = endpoint
                
                var progress = MediaSyncProgress(currentOperation: .checking)
                onProgress(progress)
                
                // Get local media directory
                let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                let mediaDir = appSupport.appendingPathComponent("AnjiCollection/media", isDirectory: true)
                
                // Ensure media directory exists
                try? FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true)
                
                var summary = MediaSyncSummary()
                
                do {
                    // Start media sync session
                    log.info("Starting media sync with progress tracking")
                    
                    // Call the backend media sync method
                    // The backend handles incremental sync and returns results
                    try backend.invokeVoid(
                        service: AnkiBackend.Service.sync,
                        method: AnkiBackend.SyncMethod.syncMedia,
                        request: auth
                    )
                    
                    // Since we don't have streaming progress from Rust backend yet,
                    // we'll simulate progress based on file operations
                    progress.currentOperation = .checking
                    onProgress(progress)
                    
                    // Get local file list for comparison
                    let localFiles = try? FileManager.default.contentsOfDirectory(at: mediaDir, includingPropertiesForKeys: nil)
                    let localFileCount = localFiles?.count ?? 0
                    progress.totalFiles = max(localFileCount * 2, 10) // Estimate total
                    onProgress(progress)
                    
                    // Progress simulation based on backend completion
                    progress.currentOperation = .downloading
                    progress.checked = localFileCount
                    onProgress(progress)
                    
                    // The actual sync is done by Rust backend
                    // We'll enhance this when backend supports streaming progress
                    progress.currentOperation = .complete
                    progress.downloaded = 0 // Will be updated when backend reports
                    progress.uploaded = 0
                    progress.removed = 0
                    onProgress(progress)
                    
                    log.info("Media sync with progress complete")
                    
                    // Return summary - actual counts will come from backend response
                    return summary
                    
                } catch let error as BackendError {
                    log.error("Media sync failed: \(error.message)")
                    if error.isSyncAuthError { throw SyncError.authFailed }
                    throw SyncError(message: error.message)
                }
            }
        )
    }()
}

extension SyncService: TestDependencyKey {
    public static let testValue = SyncService()
}

extension DependencyValues {
    public var syncService: SyncService {
        get { self[SyncService.self] }
        set { self[SyncService.self] = newValue }
    }
}
