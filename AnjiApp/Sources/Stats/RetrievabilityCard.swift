import SwiftUI
import Charts

/// Retrievability distribution (FSRS) - shows memory retention probability.
struct RetrievabilityCard: View {
    let data: [RetrievabilityPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("stats.retrievability.title")
                    .font(.headline)
                Spacer()
                if let avg = averageRetrievability {
                    Text("avg \(Int(avg))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if data.isEmpty {
                Text("stats.retrievability.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Retrievability", point.retrievabilityPercent),
                        y: .value("Cards", point.count)
                    )
                    .foregroundStyle(Color.purple.gradient)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 20)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))%")
                            }
                        }
                    }
                }
                .frame(height: 120)

                // Summary stats
                HStack {
                    if let low = lowRetrievability, low > 0 {
                        Label("\(low) < 50%", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.anjiWarning)
                    }
                    Spacer()
                    if let high = highRetrievability, high > 0 {
                        Label("\(high) > 90%", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.anjiSuccess)
                    }
                }
            }
        }
        .padding()
        .background(Color.anjiSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var averageRetrievability: Double? {
        let totalCards = data.reduce(0) { $0 + $1.count }
        guard totalCards > 0 else { return nil }
        let weightedSum = data.reduce(0.0) { $0 + (Double($1.count) * $1.retrievabilityPercent) }
        return weightedSum / Double(totalCards)
    }

    private var lowRetrievability: Int? {
        let count = data.filter { $0.retrievabilityPercent < 50 }.reduce(0) { $0 + $1.count }
        return count > 0 ? count : nil
    }

    private var highRetrievability: Int? {
        let count = data.filter { $0.retrievabilityPercent > 90 }.reduce(0) { $0 + $1.count }
        return count > 0 ? count : nil
    }
}
