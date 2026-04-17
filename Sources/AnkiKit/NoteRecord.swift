/// Mirrors the Anki note table schema.
public struct NoteRecord: Sendable, Hashable {
    public let id: Int64
    public var guid: String
    public var notetypeId: Int64
    public var modifiedAt: Int64
    public var usn: Int32
    public var tags: String
    public var fields: String          // Fields separated by \u{1f}
    public var sortField: String
    public var checksum: Int64
    public var flags: Int32
    public var data: String

    public init(
        id: Int64, guid: String, notetypeId: Int64, modifiedAt: Int64,
        usn: Int32 = -1, tags: String = "", fields: String,
        sortField: String, checksum: Int64, flags: Int32 = 0, data: String = ""
    ) {
        self.id = id; self.guid = guid; self.notetypeId = notetypeId
        self.modifiedAt = modifiedAt; self.usn = usn; self.tags = tags
        self.fields = fields; self.sortField = sortField
        self.checksum = checksum; self.flags = flags; self.data = data
    }

    /// Individual field values, split by the standard Anki field separator.
    public var fieldList: [String] {
        fields.split(separator: "\u{1f}", omittingEmptySubsequences: false).map(String.init)
    }
}
