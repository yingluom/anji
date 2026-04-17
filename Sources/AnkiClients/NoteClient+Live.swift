import AnkiKit
import AnkiServices
public import Dependencies

extension NoteClient: DependencyKey {
    public static let liveValue: Self = {
        @Dependency(\.notesService) var notes
        return Self(
            fetch: { try notes.getNote($0) },
            search: { query, limit in
                let ids = try notes.searchNoteIds(query)
                let bounded = Array(ids.prefix(limit ?? 5000))
                let batchSize = min(bounded.count, 50)
                var results: [NoteRecord] = []
                results.reserveCapacity(bounded.count)

                // Load first batch eagerly
                for nid in bounded.prefix(batchSize) {
                    if let note = try? notes.getNote(nid) {
                        results.append(note)
                    }
                }
                // Remaining notes as stubs (lazy-loaded on demand)
                for nid in bounded.dropFirst(batchSize) {
                    results.append(NoteRecord(
                        id: nid, guid: "", notetypeId: 0, modifiedAt: 0,
                        fields: "", sortField: "Loading…", checksum: 0
                    ))
                }
                return results
            },
            save:   { try notes.saveNote($0) },
            delete: { try notes.deleteNote($0) }
        )
    }()
}
