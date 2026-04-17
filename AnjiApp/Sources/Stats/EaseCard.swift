import SwiftUI
import Charts

/// Ease factor distribution card.
struct EaseCard: View {
    let data: [EasePoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats.ease.title")
                .font(.headline)

            if data.isEmpty {
                Text("stats.ease.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Ease", point.easePercent),
                        y: .value("Cards", point.count)
                    )
                    .foregroundStyle(Color.anjiTeal.gradient)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 50)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))%")
                            }
                        }
                    }
                }
                .frame(height: 120)

                HStack {
                    Text("stats.ease.average")
                        .font(.caption)
                    Spacer()
                    if let avg = averageEase {
                        Text("\(avg, specifier: "%.1f")%")
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

    private var averageEase: Double? {
        guard !data.isEmpty else { return nil }
        let totalCards = data.reduce(0) { $0 + $1.count }
        let weightedSum = data.reduce(0) { $0 + (Double($1.easePercent) * Double($1.count)) }
        return totalCards > 0 ? weightedSum / Double(totalCards) : nil
    }
}
