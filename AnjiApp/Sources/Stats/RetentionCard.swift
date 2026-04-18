import SwiftUI

/// True retention statistics showing actual memory retention rates.
struct RetentionCard: View {
    let stats: TrueRetentionStats?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats.retention.title")
                .font(.headline)
            
            if let stats = stats {
                // Time period selector could go here, showing all_time for now
                let retention = stats.allTime
                
                HStack(spacing: 20) {
                    // Young cards
                    RetentionGauge(
                        label: "stats.retention.young",
                        rate: retention.youngRate,
                        count: retention.youngTotal,
                        color: .anjiTeal
                    )
                    
                    Divider()
                    
                    // Mature cards
                    RetentionGauge(
                        label: "stats.retention.mature",
                        rate: retention.matureRate,
                        count: retention.matureTotal,
                        color: .anjiSuccess
                    )
                }
                
                // Detailed breakdown
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("stats.retention.passed", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(retention.youngPassed + retention.maturePassed)")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.anjiSuccess)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Label("stats.retention.failed", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(retention.youngFailed + retention.matureFailed)")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.anjiWarning)
                    }
                }
                .padding(.top, 4)
            } else {
                Text("stats.retention.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.anjiSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct RetentionGauge: View {
    let label: LocalizedStringKey
    let rate: Double
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: rate)
                    .stroke(color.gradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: rate)
                
                VStack(spacing: 2) {
                    Text("\(Int(rate * 100))%")
                        .font(.callout.bold())
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
