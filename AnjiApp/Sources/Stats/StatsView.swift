import SwiftUI
import AnkiClients
import Dependencies

struct StatsView: View {
    @Dependency(\.statsClient) var statsClient
    @State private var graphData: Data?
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if isLoading {
                    ProgressView()
                        .frame(maxHeight: 200)
                } else {
                    // Summary card
                    VStack(spacing: Spacing.md) {
                        Text("Statistics")
                            .anjiFont(.title)
                            .foregroundStyle(Color.anjiPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Review data is powered by the Anki engine.")
                            .anjiFont(.callout)
                            .foregroundStyle(Color.anjiSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if graphData != nil {
                            Text("Graph data loaded successfully. Detailed charts coming soon.")
                                .anjiFont(.body)
                                .foregroundStyle(Color.anjiTeal)
                                .padding()
                                .anjiCard()
                        } else {
                            ContentUnavailableView(
                                "No Data",
                                systemImage: "chart.bar",
                                description: Text("Review some cards to see your statistics.")
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .background(Color.anjiBackground)
        .navigationTitle("Stats")
        .task { await loadStats() }
    }

    private func loadStats() async {
        isLoading = true
        graphData = try? statsClient.fetchGraphs("deck:*", 365)
        isLoading = false
    }
}
