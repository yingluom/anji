import SwiftUI
import AnkiKit
import AnkiClients
import Dependencies

struct DeckListView: View {
    @Dependency(\.deckClient) var deckClient
    @State private var tree: [DeckTreeNode] = []
    @State private var isLoading = true
    @State private var showCreateSheet = false
    @State private var reviewDeckId: Int64? = nil
    @State private var showDeckDetail: DeckInfo? = nil

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
                    Section {
                        DailyQuoteView()
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                    }

                    ForEach(tree) { node in
                        DeckRowView(
                            node: node,
                            onMutated: { await loadDecks() },
                            onStartReview: { deckId in reviewDeckId = deckId },
                            onShowDetail: { deck in showDeckDetail = deck }
                        )
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.anjiBackground)
            }
        }
        .fullScreenCover(item: $reviewDeckId) { deckId in
            ReviewView(deckId: deckId) {
                reviewDeckId = nil
                Task { await loadDecks() }
            }
        }
        .sheet(item: $showDeckDetail) { deck in
            NavigationStack {
                DeckDetailView(deck: deck)
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
    let onStartReview: (Int64) -> Void
    let onShowDetail: (DeckInfo) -> Void

    @Dependency(\.deckClient) var deckClient
    @State private var showRename = false
    @State private var showDelete = false

    private var hasCardsToReview: Bool {
        node.counts.newCount > 0 || node.counts.learnCount > 0 || node.counts.reviewCount > 0
    }

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
            Button {
                handleTap()
            } label: {
                label
            }
            .buttonStyle(.plain)
        } else {
            DisclosureGroup {
                ForEach(node.children) { child in
                    DeckRowView(
                        node: child,
                        onMutated: onMutated,
                        onStartReview: onStartReview,
                        onShowDetail: onShowDetail
                    )
                }
            } label: {
                Button {
                    handleTap()
                } label: {
                    label
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func handleTap() {
        if hasCardsToReview {
            // Start review directly if there are cards to study
            onStartReview(node.id)
        } else {
            // Show deck detail if no cards available
            onShowDetail(deckInfo)
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
