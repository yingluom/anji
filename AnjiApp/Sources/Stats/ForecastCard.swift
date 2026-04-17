import SwiftUI
import Charts

/// Forecast card showing upcoming reviews for the next 30 days.
struct ForecastCard: View {
    let data: [ForecastPoint]

    private var filteredData: [ForecastPoint] {
        // Show next 30 days max for readability
        Array(data.prefix(30))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats.forecast.title")
                .font(.headline)

            if filteredData.isEmpty {
                Text("stats.forecast.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(filteredData) { point in
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Cards", point.count)
                    )
                    .foregroundStyle(Color.anjiAccent.gradient)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 120)

                HStack {
                    Text("stats.forecast.total")
                        .font(.caption)
                    Spacer()
                    Text("\(filteredData.reduce(0) { $0 + $1.count })")
                        .font(.caption.bold())
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.anjiSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
