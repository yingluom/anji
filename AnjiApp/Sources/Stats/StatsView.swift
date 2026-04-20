import SwiftUI
import AnkiClients
import Dependencies

/// Statistics dashboard with Anki desktop-aligned charts.
struct StatsView: View {
    @State private var viewModel = StatsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxHeight: 200)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        "stats.error.title",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    // Range picker
                    Picker("", selection: $viewModel.selectedRange) {
                        ForEach(StatsViewModel.StatsRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedRange) { _, _ in
                        Task { await viewModel.load() }
                    }

                    // Chart cards - ordered like Anki desktop
                    VStack(spacing: Spacing.md) {
                        TodayCard(stats: viewModel.today)
                        CardCountsCard(counts: viewModel.cardCounts)
                        AddedCard(data: viewModel.addedCards)
                        RetentionCard(stats: viewModel.trueRetention)
                        HourlyCard(data: viewModel.hourlyData)
                        StabilityCard(data: viewModel.stabilityData)
                        RetrievabilityCard(data: viewModel.retrievabilityData)
                        ForecastCard(data: viewModel.forecast)
                        ReviewsCard(data: viewModel.reviews)
                        ButtonsCard(data: viewModel.buttonsData, range: viewModel.selectedRange)
                        IntervalsCard(data: viewModel.intervals)
                        EaseCard(data: viewModel.eases)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .background(Color.anjiBackground)
        .navigationTitle("stats.title")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}
