import SwiftUI
import AnkiKit
import AnkiClients
import Dependencies
import Sharing

struct DeckListView: View {
    @Dependency(\.deckClient) var deckClient
    @Shared(.dailyQuoteEnabled) private var dailyQuoteEnabled
    @Shared(.homeStatCards) private var homeStatCards
    @State private var tree: [DeckTreeNode] = []
    @State private var isLoading = true
    @State private var showCreateSheet = false
    @State private var reviewDeckId: Int64? = nil
    @State private var showDeckDetail: DeckInfo? = nil
    @State private var todayStats: TodayStats?

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
                    // Daily Quote Section (conditional)
                    if dailyQuoteEnabled {
                        Section {
                            DailyQuoteView()
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                        }
                    }
                    
                    // Home Stat Cards Section (conditional)
                    homeStatCardsSection

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
    
    // MARK: - Home Stat Cards
    
    private var enabledStatCards: [String] {
        homeStatCards.split(separator: ",").map(String.init)
    }
    
    private func isStatCardEnabled(_ cardId: String) -> Bool {
        enabledStatCards.contains(cardId)
    }
    
    @ViewBuilder
    private var homeStatCardsSection: some View {
        if !enabledStatCards.isEmpty {
            Section {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    if isStatCardEnabled("today"), let stats = todayStats {
                        TodayCard(stats: stats)
                    }
                    if isStatCardEnabled("cardCounts") {
                        CardCountsMiniCard()
                    }
                    if isStatCardEnabled("forecast") {
                        ForecastMiniCard()
                    }
                    if isStatCardEnabled("reviews") {
                        ReviewsMiniCard()
                    }
                    if isStatCardEnabled("retention") {
                        RetentionMiniCard()
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }
        }
    }
}

// MARK: - Mini Stat Cards

struct CardCountsMiniCard: View {
    var body: some View {
        StatMiniCard(title: "卡片数量", icon: "number", color: .anjiTeal)
    }
}

struct ForecastMiniCard: View {
    var body: some View {
        StatMiniCard(title: "未来预测", icon: "calendar", color: .anjiSuccess)
    }
}

struct ReviewsMiniCard: View {
    var body: some View {
        StatMiniCard(title: "复习统计", icon: "chart.line.uptrend.xyaxis", color: .anjiAccent)
    }
}

struct RetentionMiniCard: View {
    var body: some View {
        StatMiniCard(title: "保留率", icon: "brain.head.profile", color: .purple)
    }
}

struct StatMiniCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.anjiPrimary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
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
