import SwiftUI

/// Today overview card showing studied cards, time, and accuracy.
/// Redesigned with better visual hierarchy like Anki desktop.
struct TodayCard: View {
    let stats: TodayStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("stats.today.title")
                .font(.headline)

            if let s = stats {
                // Main stats row - big numbers with labels
                HStack(spacing: 0) {
                    Spacer()
                    StatColumn(
                        value: "\(s.studiedCards)",
                        label: String(localized: "stats.today.studied"),
                        color: .primary
                    )
                    Spacer()
                    Divider().frame(height: 40)
                    Spacer()
                    StatColumn(
                        value: s.formattedTime,
                        label: String(localized: "stats.today.time"),
                        color: .primary
                    )
                    Spacer()
                    if s.studiedCards > 0 {
                        Divider().frame(height: 40)
                        Spacer()
                        StatColumn(
                            value: "\(Int(s.accuracy * 100))%",
                            label: String(localized: "stats.today.accuracy"),
                            color: s.accuracy >= 0.9 ? .green : (s.accuracy >= 0.7 ? .orange : .red)
                        )
                        Spacer()
                    }
                }
                .padding(.vertical, 8)

                // Breakdown row - colored badges
                HStack(spacing: 12) {
                    Spacer()
                    BreakdownBadge(
                        count: s.learnCount,
                        label: String(localized: "stats.legend.learn"),
                        color: Color.anjiTeal,
                        icon: "book.fill"
                    )
                    BreakdownBadge(
                        count: s.reviewCount,
                        label: String(localized: "stats.legend.review"),
                        color: Color.anjiSuccess,
                        icon: "arrow.clockwise"
                    )
                    BreakdownBadge(
                        count: s.relearnCount,
                        label: String(localized: "stats.legend.relearn"),
                        color: Color.anjiWarning,
                        icon: "exclamationmark.arrow.circlepath"
                    )
                    Spacer()
                }
            } else {
                ContentUnavailableView(
                    "stats.no_data",
                    systemImage: "chart.bar",
                    description: Text("stats.today.placeholder")
                )
            }
        }
        .padding()
        .background(Color.anjiSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Helper Views

private struct StatColumn: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct BreakdownBadge: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text("\(count)")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}
