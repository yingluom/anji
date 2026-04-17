import SwiftUI
import Charts

/// Reviews card showing historical review counts by type.
struct ReviewsCard: View {
    let data: [ReviewPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats.reviews.title")
                .font(.headline)

            if data.isEmpty {
                Text("stats.reviews.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Learn", point.learn)
                    )
                    .foregroundStyle(Color.anjiTeal)
                    .position(by: .value("Type", "Learn"))

                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Review", point.review)
                    )
                    .foregroundStyle(Color.anjiSuccess)
                    .position(by: .value("Type", "Review"))

                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Relearn", point.relearn)
                    )
                    .foregroundStyle(Color.anjiWarning)
                    .position(by: .value("Type", "Relearn"))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 140)

                // Legend
                HStack(spacing: 12) {
                    Label("stats.legend.learn", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.anjiTeal)
                    Label("stats.legend.review", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.anjiSuccess)
                    Label("stats.legend.relearn", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.anjiWarning)
                }
            }
        }
        .padding()
        .background(Color.anjiSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
