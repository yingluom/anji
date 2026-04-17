public import AnkiProto
public import Foundation
import SwiftProtobuf

/// Structured error returned by the Rust backend.
public struct BackendError: Error, Sendable {
    public let kind: Anki_Backend_BackendError.Kind
    public let message: String

    public init(kind: Anki_Backend_BackendError.Kind, message: String) {
        self.kind = kind
        self.message = message
    }

    /// Construct from raw serialised error bytes returned by the FFI layer.
    public init(errorBytes: Data) {
        if let parsed = try? Anki_Backend_BackendError(serializedBytes: errorBytes) {
            self.kind = parsed.kind
            self.message = parsed.message
        } else {
            self.kind = .ioError
            self.message = "Unknown backend error"
        }
    }

    public var isSyncAuthError: Bool { kind == .syncAuthError }
    public var isNetworkError: Bool  { kind == .networkError }
}
