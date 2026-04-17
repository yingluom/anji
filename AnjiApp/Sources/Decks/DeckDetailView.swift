import SwiftUI
import AnkiKit
import AnkiClients
import Dependencies

struct DeckDetailView: View {
    let deck: DeckInfo
    @Dependency(\.deckClient) var deckClient
    @State private var counts: DeckCounts = .zero
    @State private var showReview = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Deck header
            VStack(spacing: Spacing.md) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.anjiAccent.gradient)

                Text(deck.name)
                    .anjiFont(.title)
                    .foregroundStyle(Color.anjiPrimary)
                    .multilineTextAlignment(.center)
            }

            // Counts card
            HStack(spacing: Spacing.xl) {
                countColumn(label: "New", value: counts.newCount, color: .anjiNew)
                countColumn(label: "Learn", value: counts.learnCount, color: .anjiLearn)
                countColumn(label: "Review", value: counts.reviewCount, color: .anjiReview)
            }
            .anjiCard(elevated: true)
            .padding(.horizontal)

            Spacer()

            // Study button
            Button {
                showReview = true
            } label: {
                Label("Study Now", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AnjiPrimaryButton())
            .disabled(counts.isEmpty)
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.anjiBackground)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showReview) {
            ReviewView(deckId: deck.id) {
                showReview = false
                refreshCounts()
            }
        }
        .task { refreshCounts() }
    }

    private func refreshCounts() {
        counts = (try? deckClient.countsForDeck(deck.id)) ?? .zero
    }

    private func countColumn(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .anjiFont(.title)
                .monospacedDigit()
                .foregroundStyle(color)
            Text(label)
                .anjiFont(.caption)
                .foregroundStyle(Color.anjiSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
