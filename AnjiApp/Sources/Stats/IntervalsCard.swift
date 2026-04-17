import SwiftUI
import Charts

/// Intervals distribution card.
struct IntervalsCard: View {
    let data: [IntervalPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats.intervals.title")
                .font(.headline)

            if data.isEmpty {
                Text("stats.intervals.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Interval", point.intervalDays),
                        y: .value("Cards", point.count)
                    )
                    .foregroundStyle(Color.anjiAccent.gradient)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .frame(height: 120)

                HStack {
                    Text("stats.intervals.average")
                        .font(.caption)
                    Spacer()
                    if let avg = averageInterval {
                        Text("\(avg, specifier: "%.1f") days")
                            .font(.caption.bold())
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.anjiSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var averageInterval: Double? {
        guard !data.isEmpty else { return nil }
        let totalCards = data.reduce(0) { $0 + $1.count }
        let weightedSum = data.reduce(0) { $0 + (Double($1.intervalDays) * Double($1.count)) }
        return totalCards > 0 ? weightedSum / Double(totalCards) : nil
    }
}
