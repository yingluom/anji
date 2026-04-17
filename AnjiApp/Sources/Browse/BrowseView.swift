import SwiftUI
import AnkiKit
import AnkiClients
import Dependencies

struct BrowseView: View {
    @Dependency(\.noteClient) var noteClient
    @State private var query = ""
    @State private var notes: [NoteRecord] = []
    @State private var isSearching = false

    var body: some View {
        List {
            if notes.isEmpty && !isSearching {
                ContentUnavailableView.search
            } else {
                ForEach(notes, id: \.id) { note in
                    NavigationLink {
                        NoteEditorView(noteId: note.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.sortField.isEmpty ? "Untitled" : note.sortField)
                                .anjiFont(.body)
                                .foregroundStyle(Color.anjiPrimary)
                                .lineLimit(1)
                            if !note.tags.isEmpty {
                                Text(note.tags)
                                    .anjiFont(.caption)
                                    .foregroundStyle(Color.anjiTertiary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.anjiBackground)
        .navigationTitle("Browse")
        .searchable(text: $query, prompt: "Search notes…")
        .onSubmit(of: .search) { Task { await search() } }
        .task { await search() }
    }

    private func search() async {
        isSearching = true
        do {
            notes = try noteClient.search(query, 500)
        } catch {
            notes = []
        }
        isSearching = false
    }
}
