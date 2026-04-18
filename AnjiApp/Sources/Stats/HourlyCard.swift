import SwiftUI
import Charts

/// Hourly review distribution card showing when you study most.
struct HourlyCard: View {
    let data: [HourlyPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("stats.hourly.title")
                    .font(.headline)
                Spacer()
                if let peak = peakHour {
                    Text("stats.hourly.peak \(peak):00")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if data.isEmpty {
                Text("stats.hourly.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Hour", point.hour),
                        y: .value("Reviews", point.total)
                    )
                    .foregroundStyle(colorForHour(point.hour).gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let hour = value.as(Int.self) {
                                Text("\(hour):00")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
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
                .frame(height: 120)
                
                // Time period labels
                HStack {
                    Label("stats.hourly.morning", systemImage: "sunrise.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("stats.hourly.afternoon", systemImage: "sun.max.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("stats.hourly.evening", systemImage: "moon.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.anjiSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var peakHour: Int? {
        guard let maxPoint = data.max(by: { $0.total < $1.total }) else { return nil }
        return maxPoint.total > 0 ? maxPoint.hour : nil
    }
    
    private func colorForHour(_ hour: Int) -> Color {
        switch hour {
        case 6..<12: return Color.orange  // Morning
        case 12..<18: return Color.anjiTeal  // Afternoon
        case 18..<22: return Color.indigo  // Evening
        default: return Color.gray.opacity(0.5)  // Night/Early morning
        }
    }
}
