import SwiftUI
import Charts

/// Answer buttons pressed distribution - shows how often each answer button was used.
struct ButtonsCard: View {
    let data: ButtonsStats?
    let range: StatsViewModel.StatsRange

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("stats.buttons.title")
                    .font(.headline)
                Spacer()
                if let total = totalAnswers, total > 0 {
                    Text("\(total) answers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            guard let stats = data else {
                Text("stats.buttons.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                return
            }

            if stats.learningTotal + stats.youngTotal + stats.matureTotal == 0 {
                Text("stats.buttons.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // Stacked bar chart showing button distribution
                HStack(spacing: 12) {
                    ButtonBar(label: "Again", count: stats.againTotal, color: .anjiAgain)
                    ButtonBar(label: "Hard", count: stats.hardTotal, color: .anjiHard)
                    ButtonBar(label: "Good", count: stats.goodTotal, color: .anjiGood)
                    ButtonBar(label: "Easy", count: stats.easyTotal, color: .anjiEasy)
                }
                .frame(height: 100)

                // Legend with percentages
                HStack(spacing: 16) {
                    Label(againPercent, systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.anjiAgain)
                    Label(hardPercent, systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.anjiHard)
                    Label(goodPercent, systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.anjiGood)
                    Label(easyPercent, systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.anjiEasy)
                }
            }
        }
        .padding()
        .background(Color.anjiSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var totalAnswers: Int? {
        guard let stats = data else { return nil }
        return stats.learningTotal + stats.youngTotal + stats.matureTotal
    }

    private var againPercent: String {
        guard let total = totalAnswers, total > 0, let stats = data else { return "0%" }
        return "\(Int(Double(stats.againTotal) / Double(total) * 100))%"
    }

    private var hardPercent: String {
        guard let total = totalAnswers, total > 0, let stats = data else { return "0%" }
        return "\(Int(Double(stats.hardTotal) / Double(total) * 100))%"
    }

    private var goodPercent: String {
        guard let total = totalAnswers, total > 0, let stats = data else { return "0%" }
        return "\(Int(Double(stats.goodTotal) / Double(total) * 100))%"
    }

    private var easyPercent: String {
        guard let total = totalAnswers, total > 0, let stats = data else { return "0%" }
        return "\(Int(Double(stats.easyTotal) / Double(total) * 100))%"
    }
}

private struct ButtonBar: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.caption.bold())
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 40)
                .frame(maxHeight: .infinity, alignment: .bottom)
            Text(label)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
    }
}
