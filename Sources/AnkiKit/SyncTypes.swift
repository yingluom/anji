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

    public init(uploaded: Int = 0, downloaded: Int = 0, removed: Int = 0) {
        self.uploaded = uploaded
        self.downloaded = downloaded
        self.removed = removed
    }
}
