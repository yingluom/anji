import Foundation

/// Mirrors the Anki card table schema. Only the Rust backend writes to the
/// database; this struct is a read-only snapshot for display purposes.
public struct CardRecord: Sendable {
    public let id: Int64
    public var noteId: Int64
    public var deckId: Int64
    public var templateIndex: Int32
    public var modifiedAt: Int64
    public var usn: Int32
    public var cardType: Int16
    public var queue: Int16
    public var due: Int32
    public var interval: Int32
    public var easeFactor: Int32
    public var reps: Int32
    public var lapses: Int32
    public var remainingSteps: Int32
    public var originalDue: Int32
    public var originalDeckId: Int64
    public var flags: Int32
    public var customData: String

    public init(
        id: Int64, noteId: Int64, deckId: Int64, templateIndex: Int32 = 0,
        modifiedAt: Int64, usn: Int32 = -1, cardType: Int16 = 0,
        queue: Int16 = 0, due: Int32 = 0, interval: Int32 = 0,
        easeFactor: Int32 = 0, reps: Int32 = 0, lapses: Int32 = 0,
        remainingSteps: Int32 = 0, originalDue: Int32 = 0,
        originalDeckId: Int64 = 0, flags: Int32 = 0, customData: String = ""
    ) {
        self.id = id; self.noteId = noteId; self.deckId = deckId
        self.templateIndex = templateIndex; self.modifiedAt = modifiedAt
        self.usn = usn; self.cardType = cardType; self.queue = queue
        self.due = due; self.interval = interval; self.easeFactor = easeFactor
        self.reps = reps; self.lapses = lapses
        self.remainingSteps = remainingSteps; self.originalDue = originalDue
        self.originalDeckId = originalDeckId; self.flags = flags
        self.customData = customData
    }
}
