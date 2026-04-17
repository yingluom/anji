import SwiftUI
import AnkiKit
import AnkiClients
import Dependencies

struct DeckListView: View {
    @Dependency(\.deckClient) var deckClient
    @State private var tree: [DeckTreeNode] = []
    @State private var isLoading = true
    @State private var showCreateSheet = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if tree.isEmpty {
                ContentUnavailableView(
                    "No Decks Yet",
                    systemImage: "rectangle.stack",
                    description: Text("Tap the sync button to download your decks from AnkiWeb.")
                )
            } else {
                List {
                    ForEach(tree) { node in
                        DeckRowView(node: node) { await loadDecks() }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.anjiBackground)
                .navigationDestination(for: DeckInfo.self) { deck in
                    DeckDetailView(deck: deck)
                }
            }
        }
        .navigationTitle("Decks")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCreateSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateDeckSheet {
                showCreateSheet = false
                Task { await loadDecks() }
            }
        }
        .task { await loadDecks() }
        .refreshable { await loadDecks() }
    }

    private func loadDecks() async {
        do {
            tree = try deckClient.fetchTree()
        } catch {
            tree = []
        }
        isLoading = false
    }
}

// MARK: - Row

private struct DeckRowView: View {
    let node: DeckTreeNode
    let onMutated: () async -> Void

    @Dependency(\.deckClient) var deckClient
    @State private var showRename = false
    @State private var showDelete = false

    var body: some View {
        rowContent
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button { showDelete = true } label: { Label("Delete", systemImage: "trash") }
                    .tint(.anjiDanger)
                Button { showRename = true } label: { Label("Rename", systemImage: "pencil") }
                    .tint(.anjiWarning)
            }
            .alert("Delete \"\(node.name)\"?", isPresented: $showDelete) {
                Button("Delete", role: .destructive) {
                    Task {
                        try? deckClient.delete(node.id)
                        await onMutated()
                    }
                }
            } message: {
                Text("This deck and all its cards will be permanently removed.")
            }
            .sheet(isPresented: $showRename) {
                RenameDeckSheet(deckId: node.id, currentName: node.fullName) {
                    showRename = false
                    Task { await onMutated() }
                }
            }
    }

    @ViewBuilder
    private var rowContent: some View {
        if node.children.isEmpty {
            NavigationLink(value: deckInfo) { label }
        } else {
            DisclosureGroup {
                ForEach(node.children) { child in
                    DeckRowView(node: child, onMutated: onMutated)
                }
            } label: {
                NavigationLink(value: deckInfo) { label }
            }
        }
    }

    private var label: some View {
        HStack {
            Text(node.name)
                .anjiFont(.body)
                .foregroundStyle(Color.anjiPrimary)
            Spacer()
            CountBadgesView(counts: node.counts)
        }
    }

    private var deckInfo: DeckInfo {
        DeckInfo(id: node.id, name: node.fullName, counts: node.counts)
    }
}

// MARK: - Create Deck

private struct CreateDeckSheet: View {
    let onDone: () -> Void
    @Dependency(\.deckClient) var deckClient
    @State private var name = ""
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Deck name (use :: for subdecks)", text: $name)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isSaving = true
                            _ = try? deckClient.create(name.trimmingCharacters(in: .whitespaces))
                            onDone()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }
}

// MARK: - Rename Deck

private struct RenameDeckSheet: View {
    let deckId: Int64
    let currentName: String
    let onDone: () -> Void
    @Dependency(\.deckClient) var deckClient
    @State private var name = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("Deck name", text: $name).autocorrectionDisabled() }
            }
            .navigationTitle("Rename Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            try? deckClient.rename(deckId, name.trimmingCharacters(in: .whitespaces))
                            onDone()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { name = currentName }
        }
    }
}
