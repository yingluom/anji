/// Notetype information used for creating new notes.
public struct NotetypeInfo: Sendable, Identifiable, Hashable {
    public let id: Int64
    public var name: String
    public var fieldNames: [String]

    public init(id: Int64, name: String, fieldNames: [String] = []) {
        self.id = id
        self.name = name
        self.fieldNames = fieldNames
    }
}

/// Template for creating a new note. Holds fields pre-populated with
/// the correct count from the notetype definition.
public struct NewNoteTemplate: Sendable {
    public var notetypeId: Int64
    public var fields: [String]
    public var tags: [String]

    public init(notetypeId: Int64, fields: [String], tags: [String] = []) {
        self.notetypeId = notetypeId
        self.fields = fields
        self.tags = tags
    }
}
