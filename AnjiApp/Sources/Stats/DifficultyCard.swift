import SwiftUI
import Charts

/// FSRS difficulty distribution showing card difficulty levels.
struct DifficultyCard: View {
    let data: [DifficultyPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("stats.difficulty.title")
                    .font(.headline)
                Spacer()
                if let avg = averageDifficulty {
                    Text("stats.difficulty.avg \(avg, specifier: "%.1f")%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if data.isEmpty {
                Text("stats.difficulty.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // Bucket into easy/medium/hard
                let buckets = bucketedData()
                
                HStack(spacing: 16) {
                    ForEach(buckets) { bucket in
                        VStack(spacing: 8) {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(bucket.color.opacity(0.2))
                                    .frame(height: 80)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(bucket.color.gradient)
                                    .frame(height: CGFloat(bucket.count) / CGFloat(maxCount()) * 80)
                            }
                            .frame(width: 60)
                            
                            Text(bucket.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("\(bucket.count)")
                                .font(.caption.bold())
                                .foregroundStyle(bucket.color)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.anjiSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private struct DifficultyBucket: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let color: Color
    }
    
    private func bucketedData() -> [DifficultyBucket] {
        let easyCount = data.filter { $0.difficulty < 40 }.reduce(0) { $0 + $1.count }
        let mediumCount = data.filter { $0.difficulty >= 40 && $0.difficulty < 70 }.reduce(0) { $0 + $1.count }
        let hardCount = data.filter { $0.difficulty >= 70 }.reduce(0) { $0 + $1.count }
        
        return [
            DifficultyBucket(label: "简单", count: easyCount, color: .anjiSuccess),
            DifficultyBucket(label: "中等", count: mediumCount, color: .anjiTeal),
            DifficultyBucket(label: "困难", count: hardCount, color: .anjiWarning)
        ]
    }
    
    private func maxCount() -> Int {
        let buckets = bucketedData()
        return buckets.map { $0.count }.max() ?? 1
    }
    
    private var averageDifficulty: Double? {
        let totalCards = data.reduce(0) { $0 + $1.count }
        guard totalCards > 0 else { return nil }
        let weightedSum = data.reduce(0) { $0 + (Double($1.difficulty) * Double($1.count)) }
        return weightedSum / Double(totalCards)
    }
}
