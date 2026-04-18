import SwiftUI
import Charts

/// FSRS stability distribution showing memory stability in days.
struct StabilityCard: View {
    let data: [StabilityPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("stats.stability.title")
                    .font(.headline)
                Spacer()
                if let median = medianStability {
                    Text("stats.stability.median \(median)d")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if data.isEmpty {
                Text("stats.stability.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // Bucket data into ranges for cleaner display
                let buckets = bucketedData()
                
                Chart(buckets) { bucket in
                    BarMark(
                        x: .value("Range", bucket.label),
                        y: .value("Cards", bucket.count)
                    )
                    .foregroundStyle(colorForStability(bucket.maxDays).gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.caption2)
                                    .rotationEffect(.degrees(-45))
                            }
                        }
                    }
                }
                .frame(height: 120)
                
                // Legend
                HStack(spacing: 12) {
                    Label("stats.stability.short", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.red.opacity(0.7))
                    Spacer()
                    Label("stats.stability.medium", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.anjiTeal)
                    Spacer()
                    Label("stats.stability.long", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.anjiSuccess)
                }
            }
        }
        .padding()
        .background(Color.anjiSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private struct StabilityBucket: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let maxDays: Int
    }
    
    private func bucketedData() -> [StabilityBucket] {
        let buckets = [
            (0..<1, "<1d"),
            (1..<3, "1-3d"),
            (3..<7, "3-7d"),
            (7..<14, "1-2w"),
            (14..<30, "2-4w"),
            (30..<90, "1-3m"),
            (90..<180, "3-6m"),
            (180..<365, "6-12m"),
            (365..<1000, ">1y")
        ]
        
        return buckets.map { range, label in
            let count = data.filter { range.contains($0.stabilityDays) }.reduce(0) { $0 + $1.count }
            return StabilityBucket(label: label, count: count, maxDays: range.upperBound - 1)
        }
    }
    
    private var medianStability: Int? {
        let totalCards = data.reduce(0) { $0 + $1.count }
        guard totalCards > 0 else { return nil }
        
        let sorted = data.sorted { $0.stabilityDays < $1.stabilityDays }
        var cumulative = 0
        for point in sorted {
            cumulative += point.count
            if cumulative >= totalCards / 2 {
                return point.stabilityDays
            }
        }
        return nil
    }
    
    private func colorForStability(_ days: Int) -> Color {
        switch days {
        case 0..<7: return Color.red.opacity(0.7)  // Short term
        case 7..<30: return Color.anjiTeal  // Medium
        default: return Color.anjiSuccess  // Long term
        }
    }
}
