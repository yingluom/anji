import SwiftUI

/// Today overview card showing studied cards, time, and accuracy.
struct TodayCard: View {
    let stats: TodayStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("stats.today.title")
                .font(.headline)

            if let s = stats {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(s.studiedCards)")
                            .font(.system(size: 32, weight: .bold))
                        Text("stats.today.studied")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(s.formattedTime)
                            .font(.system(size: 32, weight: .bold))
                        Text("stats.today.time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(s.accuracy * 100))%")
                            .font(.system(size: 32, weight: .bold))
                        Text("stats.today.accuracy")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    Label("\(s.learnCount)", systemImage: "book.fill")
                        .font(.caption)
                        .foregroundStyle(Color.anjiTeal)
                    Label("\(s.reviewCount)", systemImage: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(Color.anjiSuccess)
                    Label("\(s.relearnCount)", systemImage: "exclamationmark.arrow.circlepath")
                        .font(.caption)
                        .foregroundStyle(Color.anjiWarning)
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
