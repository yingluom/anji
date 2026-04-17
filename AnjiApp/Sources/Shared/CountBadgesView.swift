import SwiftUI
import AnkiKit

/// Compact new/learn/review count badges.
struct CountBadgesView: View {
    let counts: DeckCounts

    var body: some View {
        HStack(spacing: 6) {
            if counts.newCount > 0 {
                badge(counts.newCount, color: .anjiNew)
            }
            if counts.learnCount > 0 {
                badge(counts.learnCount, color: .anjiLearn)
            }
            if counts.reviewCount > 0 {
                badge(counts.reviewCount, color: .anjiReview)
            }
        }
    }

    private func badge(_ count: Int, color: Color) -> some View {
        Text("\(count)")
            .anjiFont(.caption)
            .monospacedDigit()
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }
}
