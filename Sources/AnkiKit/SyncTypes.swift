import Foundation

/// Direction for a full (non-incremental) sync.
public enum SyncDirection: Sendable {
    case upload
    case download
}

/// Represents a sync failure.
public struct SyncError: Error, Sendable, Equatable {
    public let message: String
    public let isRetryable: Bool

    public init(message: String, isRetryable: Bool = true) {
        self.message = message
        self.isRetryable = isRetryable
    }

    public static let authFailed =
        SyncError(message: "Authentication failed", isRetryable: false)
    public static let networkUnavailable =
        SyncError(message: "Network unavailable", isRetryable: true)
    public static let fullSyncRequired =
        SyncError(message: "Full sync required", isRetryable: false)
}

/// Summary returned after a successful collection sync.
public struct SyncSummary: Sendable, Equatable {
    public var cardsPushed: Int
    public var cardsPulled: Int
    public var notesPushed: Int
    public var notesPulled: Int

    public init(
        cardsPushed: Int = 0, cardsPulled: Int = 0,
        notesPushed: Int = 0, notesPulled: Int = 0
    ) {
        self.cardsPushed = cardsPushed
        self.cardsPulled = cardsPulled
        self.notesPushed = notesPushed
        self.notesPulled = notesPulled
    }

    public var isUpToDate: Bool {
        cardsPushed == 0 && cardsPulled == 0 &&
        notesPushed == 0 && notesPulled == 0
    }
}

/// Summary returned after a media sync.
public struct MediaSyncSummary: Sendable, Equatable {
    public var uploaded: Int
    public var downloaded: Int
    public var removed: Int
    public var checked: Int
    public var errors: [String]
    
    public init(uploaded: Int = 0, downloaded: Int = 0, removed: Int = 0, checked: Int = 0, errors: [String] = []) {
        self.uploaded = uploaded
        self.downloaded = downloaded
        self.removed = removed
        self.checked = checked
        self.errors = errors
    }
}

/// Progress update for media sync operations.
public struct MediaSyncProgress: Sendable, Equatable {
    public var currentFile: String
    public var downloaded: Int
    public var uploaded: Int
    public var removed: Int
    public var checked: Int
    public var totalFiles: Int
    public var currentOperation: MediaSyncOperation
    
    public init(
        currentFile: String = "",
        downloaded: Int = 0,
        uploaded: Int = 0,
        removed: Int = 0,
        checked: Int = 0,
        totalFiles: Int = 0,
        currentOperation: MediaSyncOperation = .checking
    ) {
        self.currentFile = currentFile
        self.downloaded = downloaded
        self.uploaded = uploaded
        self.removed = removed
        self.checked = checked
        self.totalFiles = totalFiles
        self.currentOperation = currentOperation
    }
    
    public var progress: Double {
        guard totalFiles > 0 else { return 0 }
        return Double(checked + downloaded + uploaded + removed) / Double(totalFiles)
    }
}

public enum MediaSyncOperation: Sendable, Equatable {
    case checking      // Checking local files
    case downloading // Downloading files from server
    case uploading   // Uploading files to server
    case removing    // Removing files
    case complete    // Sync complete
}

/// Information about a media file for sync.
public struct MediaFileInfo: Sendable, Equatable {
    public let filename: String
    public let size: Int64
    public let md5: String?
    public let modTime: Date?
    
    public init(filename: String, size: Int64 = 0, md5: String? = nil, modTime: Date? = nil) {
        self.filename = filename
        self.size = size
        self.md5 = md5
        self.modTime = modTime
    }
}
