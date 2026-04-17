import SwiftUI
import AnkiKit
import AnkiClients
import AnkiServices
import Dependencies

struct NoteEditorView: View {
    let noteId: Int64

    @Dependency(\.noteClient) var noteClient
    @Dependency(\.notetypesService) var notetypes
    @State private var note: NoteRecord?
    @State private var fieldNames: [String] = []
    @State private var fieldValues: [String] = []
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let note {
                Form {
                    ForEach(fieldValues.indices, id: \.self) { i in
                        Section(header: Text(i < fieldNames.count ? fieldNames[i] : "Field \(i + 1)")) {
                            TextEditor(text: $fieldValues[i])
                                .frame(minHeight: 60)
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Edit Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(note == nil || isSaving)
            }
        }
        .task { await loadNote() }
    }

    private func loadNote() async {
        guard let loaded = try? noteClient.fetch(noteId) else { return }
        note = loaded
        fieldValues = loaded.fieldList

        if let nt = try? notetypes.getNotetype(loaded.notetypeId) {
            fieldNames = nt.fieldNames
        }
    }

    private func save() async {
        guard var n = note else { return }
        isSaving = true
        n.fields = fieldValues.joined(separator: "\u{1f}")
        try? noteClient.save(n)
        isSaving = false
        dismiss()
    }
}
