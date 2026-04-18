import SwiftUI
import Charts

/// Card counts distribution showing new/learning/review/suspended cards.
/// Mirrors Anki desktop's card counts chart.
struct CardCountsCard: View {
    let counts: CardCountsData?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats.card_counts.title")
                .font(.headline)

            if let c = counts {
                // Horizontal bar chart
                Chart {
                    BarMark(
                        x: .value("Count", c.newCards),
                        y: .value("Type", String(localized: "stats.card_counts.new"))
                    )
                    .foregroundStyle(Color.anjiNew)

                    BarMark(
                        x: .value("Count", c.learn),
                        y: .value("Type", String(localized: "stats.card_counts.learn"))
                    )
                    .foregroundStyle(Color.anjiTeal)

                    BarMark(
                        x: .value("Count", c.young),
                        y: .value("Type", String(localized: "stats.card_counts.young"))
                    )
                    .foregroundStyle(Color.anjiReview)

                    BarMark(
                        x: .value("Count", c.mature),
                        y: .value("Type", String(localized: "stats.card_counts.mature"))
                    )
                    .foregroundStyle(Color.anjiSuccess)

                    if c.suspended > 0 {
                        BarMark(
                            x: .value("Count", c.suspended),
                            y: .value("Type", String(localized: "stats.card_counts.suspended"))
                        )
                        .foregroundStyle(Color.anjiWarning.opacity(0.7))
                    }

                    if c.buried > 0 {
                        BarMark(
                            x: .value("Count", c.buried),
                            y: .value("Type", String(localized: "stats.card_counts.buried"))
                        )
                        .foregroundStyle(Color.gray)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text("\(v)")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(String.self) {
                                Text(v)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 160)

                // Total count footer
                HStack {
                    Text("stats.card_counts.total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(c.total)")
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                }
                .padding(.top, 4)
            } else {
                ContentUnavailableView(
                    "stats.no_data",
                    systemImage: "rectangle.stack",
                    description: Text("stats.card_counts.placeholder")
                )
            }
        }
        .padding()
        .background(Color.anjiSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Data Model

struct CardCountsData: Identifiable {
    let id = UUID()
    let newCards: Int
    let learn: Int
    let young: Int
    let mature: Int
    let suspended: Int
    let buried: Int

    var total: Int { newCards + learn + young + mature }
}
