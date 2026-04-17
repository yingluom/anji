import SwiftUI
import AnkiSync
import AnkiClients
import Sharing

/// The main tab view — Decks, Browse, Stats, Settings.
struct MainTabView: View {
    @Binding var pendingReviewDeckId: Int64?
    @State private var showSync = false
    @State private var refreshToken = UUID()

    var body: some View {
        TabView {
            Tab("tab.decks", systemImage: "rectangle.stack.fill") {
                NavigationStack {
                    DeckListView()
                        .id(refreshToken)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button { showSync = true } label: {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                            }
                        }
                }
            }

            Tab(role: .search) {
                NavigationStack {
                    BrowseView()
                        .id(refreshToken)
                }
            } label: {
                Label("tab.browse", systemImage: "magnifyingglass")
            }

            Tab("tab.stats", systemImage: "chart.bar.fill") {
                NavigationStack {
                    StatsView()
                        .id(refreshToken)
                }
            }

            Tab("tab.settings", systemImage: "gearshape.fill") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tint(.anjiAccent)
        .sheet(isPresented: $showSync) {
            refreshToken = UUID()
        } content: {
            SyncSheet(isPresented: $showSync)
        }
        .fullScreenCover(item: $pendingReviewDeckId) { deckId in
            ReviewView(deckId: deckId) {
                pendingReviewDeckId = nil
                refreshToken = UUID()
            }
        }
    }
}

extension Int64: @retroactive Identifiable {
    public var id: Int64 { self }
}
