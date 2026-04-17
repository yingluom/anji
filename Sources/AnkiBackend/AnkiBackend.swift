import AnkiRustLib
import AnkiProto
public import Foundation
public import SwiftProtobuf

/// Thread-safe wrapper around the Anki Rust backend.
///
/// All communication with Rust goes through protobuf-encoded bytes:
///   Swift request → serializedData() → C FFI → Rust → response bytes → Swift struct
///
/// This class is `Sendable` and guarded by `NSLock`; it is safe to call from
/// any thread or Swift concurrency context.
public final class AnkiBackend: Sendable {
    private let handle: Int64
    private let lock = NSLock()

    // Stored paths so we can reopen after a full sync replaces the database.
    private nonisolated(unsafe) var _collectionPath: String?
    private nonisolated(unsafe) var _mediaFolderPath: String?
    private nonisolated(unsafe) var _mediaDbPath: String?

    /// The media folder path for the currently open collection, if any.
    public var mediaFolderPath: String? { _mediaFolderPath }

    // MARK: - Lifecycle

    public init(preferredLanguages: [String] = ["en"]) throws {
        var initMsg = Anki_Backend_BackendInit()
        initMsg.preferredLangs = preferredLanguages
        initMsg.server = false

        let initBytes = try initMsg.serializedData()
        var ptr: Int64 = 0

        let status = initBytes.withUnsafeBytes { buf in
            anki_open_backend(
                buf.baseAddress?.assumingMemoryBound(to: UInt8.self),
                buf.count,
                &ptr
            )
        }
        guard status == 0, ptr != 0 else {
            throw BackendError(kind: .ioError, message: "Failed to initialise Anki backend")
        }
        self.handle = ptr
    }

    deinit {
        anki_close_backend(handle)
    }

    // MARK: - Collection Management

    public func openCollection(
        collectionPath: String,
        mediaFolderPath: String,
        mediaDbPath: String
    ) throws {
        _collectionPath = collectionPath
        _mediaFolderPath = mediaFolderPath
        _mediaDbPath = mediaDbPath

        var req = Anki_Collection_OpenCollectionRequest()
        req.collectionPath = collectionPath
        req.mediaFolderPath = mediaFolderPath
        req.mediaDbPath = mediaDbPath
        try invokeVoid(service: Service.collection, method: CollectionMethod.open, request: req)
    }

    /// Reopen the collection after a full sync that replaced the database file.
    public func reopenAfterFullSync() throws {
        guard let path = _collectionPath,
              let media = _mediaFolderPath,
              let db = _mediaDbPath else { return }
        try? closeCollection()
        try openCollection(collectionPath: path, mediaFolderPath: media, mediaDbPath: db)
    }

    public func closeCollection(downgradeToSchema11: Bool = false) throws {
        var req = Anki_Collection_CloseCollectionRequest()
        req.downgradeToSchema11 = downgradeToSchema11
        try invokeVoid(service: Service.collection, method: CollectionMethod.close, request: req)
    }

    /// Repairs database inconsistencies.
    public func checkDatabase() throws {
        _ = try rawCall(service: Service.collectionOps, method: CollectionOpsMethod.checkDatabase, input: Data())
    }

    // MARK: - Typed RPC (package-internal — use via AnkiServices)

    package func invoke<Req: SwiftProtobuf.Message, Resp: SwiftProtobuf.Message>(
        service: UInt32, method: UInt32, request: Req
    ) throws -> Resp {
        let responseBytes = try call(service: service, method: method, request: request)
        return try Resp(serializedBytes: responseBytes)
    }

    package func invoke<Resp: SwiftProtobuf.Message>(
        service: UInt32, method: UInt32
    ) throws -> Resp {
        let responseBytes = try rawCall(service: service, method: method, input: Data())
        return try Resp(serializedBytes: responseBytes)
    }

    package func call(
        service: UInt32, method: UInt32,
        request: some SwiftProtobuf.Message
    ) throws -> Data {
        try rawCall(service: service, method: method, input: try request.serializedData())
    }

    package func call(service: UInt32, method: UInt32) throws -> Data {
        try rawCall(service: service, method: method, input: Data())
    }

    package func invokeVoid(
        service: UInt32, method: UInt32,
        request: some SwiftProtobuf.Message
    ) throws {
        _ = try call(service: service, method: method, request: request)
    }

    package func invokeVoid(service: UInt32, method: UInt32) throws {
        _ = try call(service: service, method: method)
    }

    // MARK: - Raw FFI

    private func rawCall(service: UInt32, method: UInt32, input: Data) throws -> Data {
        lock.lock()
        defer { lock.unlock() }

        var outPtr: UnsafeMutablePointer<UInt8>? = nil
        var outLen: Int = 0

        let status: Int32
        if input.isEmpty {
            status = anki_run_method(handle, service, method, nil, 0, &outPtr, &outLen)
        } else {
            status = input.withUnsafeBytes { buf in
                anki_run_method(
                    handle, service, method,
                    buf.baseAddress?.assumingMemoryBound(to: UInt8.self), buf.count,
                    &outPtr, &outLen
                )
            }
        }

        defer { if let outPtr { anki_free_response(outPtr, outLen) } }

        let responseData = if let outPtr, outLen > 0 {
            Data(bytes: outPtr, count: outLen)
        } else {
            Data()
        }

        switch status {
        case 0:  return responseData
        case 1:  throw BackendError(errorBytes: responseData)
        default: throw BackendError(kind: .ioError, message: "FFI error (status \(status))")
        }
    }
}

// MARK: - Service / Method Constants

extension AnkiBackend {
    package enum Service {
        package static let sync: UInt32          = 1
        package static let collectionOps: UInt32 = 2
        package static let collection: UInt32    = 3
        package static let cards: UInt32         = 5
        package static let decks: UInt32         = 7
        package static let scheduler: UInt32     = 13
        package static let notetypes: UInt32     = 23
        package static let notes: UInt32         = 25
        package static let cardRendering: UInt32 = 27
        package static let search: UInt32        = 29
        package static let importExport: UInt32  = 37
        package static let stats: UInt32         = 41
        package static let tags: UInt32          = 43
    }

    package enum CollectionOpsMethod {
        package static let checkDatabase: UInt32 = 0
        package static let undo: UInt32          = 2
    }

    package enum CollectionMethod {
        package static let open: UInt32  = 0
        package static let close: UInt32 = 1
    }

    package enum SyncMethod {
        package static let syncMedia: UInt32           = 0
        package static let syncLogin: UInt32           = 3
        package static let syncStatus: UInt32          = 4
        package static let syncCollection: UInt32      = 5
        package static let fullUploadOrDownload: UInt32 = 6
    }

    package enum SchedulerMethod {
        package static let getQueuedCards: UInt32    = 3
        package static let answerCard: UInt32        = 4
        package static let countsForDeckToday: UInt32 = 10
    }

    package enum NotesMethod {
        package static let newNote: UInt32     = 0
        package static let addNote: UInt32     = 1
        package static let removeNotes: UInt32 = 3
        package static let updateNotes: UInt32 = 5
        package static let getNote: UInt32     = 6
    }

    package enum DecksMethod {
        package static let newDeck: UInt32          = 0
        package static let addDeck: UInt32          = 1
        package static let getDeckTree: UInt32      = 4
        package static let getDeck: UInt32          = 8
        package static let getDeckNames: UInt32     = 13
        package static let removeDecks: UInt32      = 16
        package static let renameDeck: UInt32       = 18
        package static let setCurrentDeck: UInt32   = 22
        package static let getCurrentDeck: UInt32   = 23
    }

    package enum SearchMethod {
        package static let searchCards: UInt32 = 1
        package static let searchNotes: UInt32 = 2
    }

    package enum CardRenderingMethod {
        package static let renderExistingCard: UInt32 = 6
    }

    package enum NotetypesMethod {
        package static let getNotetype: UInt32     = 6
        package static let getNotetypeNames: UInt32 = 8
    }

    package enum ImportExportMethod {
        package static let importAnkiPackage: UInt32       = 2
        package static let exportCollectionPackage: UInt32  = 1
    }

    package enum StatsMethod {
        package static let cardStats: UInt32 = 0
        package static let graphs: UInt32    = 2
    }
}
