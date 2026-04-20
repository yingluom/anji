import SwiftUI
import Charts

/// Added cards over time - shows when cards were added to the collection.
struct AddedCard: View {
    let data: [AddedPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("stats.added.title")
                    .font(.headline)
                Spacer()
                Text("\(totalAdded) cards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if data.isEmpty {
                Text("stats.added.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Added", point.count)
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

                // Average per day
                HStack {
                    Text("stats.added.avg_per_day")
                        .font(.caption)
                    Spacer()
                    Text("\(avgPerDay, specifier: "%.1f")")
                        .font(.caption.bold())
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.anjiSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var totalAdded: Int {
        data.reduce(0) { $0 + $1.count }
    }

    private var avgPerDay: Double {
        guard !data.isEmpty else { return 0 }
        return Double(totalAdded) / Double(data.count)
    }
}
