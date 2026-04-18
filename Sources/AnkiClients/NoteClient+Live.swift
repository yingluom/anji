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
                let bounded = Array(ids.prefix(limit ?? 500))
                var results: [NoteRecord] = []
                results.reserveCapacity(bounded.count)

                // Load all notes (batch loading with error handling)
                for nid in bounded {
                    if let note = try? notes.getNote(nid) {
                        results.append(note)
                    }
                    // Silently skip notes that fail to load
                }
                return results
            },
            save:   { try notes.saveNote($0) },
            delete: { try notes.deleteNote($0) }
        )
    }()
}
