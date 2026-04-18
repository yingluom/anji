import ActivityKit
import SwiftUI

/// Live Activity attributes for Anji study session
struct AnjiStudyAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var cardFront: String
        var cardBack: String
        var showingAnswer: Bool
        var remainingNew: Int
        var remainingLearning: Int
        var remainingReview: Int
        var totalReviewed: Int
    }

    var deckName: String
}

/// Live Activity view for Dynamic Island and Lock Screen
@available(iOS 16.1, *)
struct AnjiLiveActivityView: View {
    let context: ActivityViewContext<AnjiStudyAttributes>

    var body: some View {
        ZStack {
            // Background gradient based on card type
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                // Header with deck name and counts
                HStack {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.caption)
                    Text(context.attributes.deckName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer()

                    // Count badges
                    HStack(spacing: 4) {
                        if context.state.remainingNew > 0 {
                            badge(text: "\(context.state.remainingNew)", color: .blue)
                        }
                        if context.state.remainingLearning > 0 {
                            badge(text: "\(context.state.remainingLearning)", color: .red)
                        }
                        if context.state.remainingReview > 0 {
                            badge(text: "\(context.state.remainingReview)", color: .green)
                        }
                    }
                }
                .foregroundStyle(.white.opacity(0.9))

                // Card content
                VStack(spacing: 4) {
                    Text(truncatedText(context.state.cardFront))
                        .font(.system(size: context.state.cardFront.count > 20 ? 14 : 16, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    if context.state.showingAnswer {
                        Divider()
                            .background(.white.opacity(0.3))
                            .padding(.horizontal, 8)

                        Text(truncatedText(context.state.cardBack))
                            .font(.system(size: context.state.cardBack.count > 20 ? 12 : 14))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(.white.opacity(0.9))
                    } else {
                        Text("Tap to reveal answer")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.top, 4)
                    }
                }
                .foregroundStyle(.white)

                // Progress indicator
                HStack {
                    Text("Reviewed: \(context.state.totalReviewed)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(12)
        }
        .frame(height: context.displaySize == .minimal ? 40 : (context.displaySize == .compact ? 80 : 120))
    }

    private var gradientColors: [Color] {
        if context.state.showingAnswer {
            return [Color.purple.opacity(0.8), Color.indigo.opacity(0.9)]
        } else {
            return [Color.accentColor.opacity(0.8), Color.blue.opacity(0.9)]
        }
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.7))
            .clipShape(Capsule())
    }

    private func truncatedText(_ text: String) -> String {
        // Remove HTML tags and truncate if too long
        let cleaned = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        if cleaned.count > 60 {
            return String(cleaned.prefix(60)) + "..."
        }
        return cleaned
    }
}

/// Manager for Live Activity lifecycle
@available(iOS 16.1, *)
@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<AnjiStudyAttributes>?

    func startActivity(deckName: String, cardFront: String, counts: DeckCounts, totalReviewed: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // End any existing activity
        endActivity()

        let attributes = AnjiStudyAttributes(deckName: deckName)
        let initialState = AnjiStudyAttributes.ContentState(
            cardFront: cardFront,
            cardBack: "",
            showingAnswer: false,
            remainingNew: counts.newCount,
            remainingLearning: counts.learnCount,
            remainingReview: counts.reviewCount,
            totalReviewed: totalReviewed
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    func updateActivity(cardFront: String, cardBack: String, showingAnswer: Bool, counts: DeckCounts, totalReviewed: Int) {
        guard let activity = currentActivity else { return }

        let newState = AnjiStudyAttributes.ContentState(
            cardFront: cardFront,
            cardBack: cardBack,
            showingAnswer: showingAnswer,
            remainingNew: counts.newCount,
            remainingLearning: counts.learnCount,
            remainingReview: counts.reviewCount,
            totalReviewed: totalReviewed
        )

        Task {
            await activity.update(using: newState)
        }
    }

    func endActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    var isActive: Bool {
        currentActivity != nil
    }
}

// MARK: - Widget Extension Placeholder
// This would normally be in a separate widget extension target
// For now, we define the Live Activity views inline above

@available(iOS 16.1, *)
struct AnjiLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AnjiStudyAttributes.self) { context in
            // Lock screen / banner view
            AnjiLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "rectangle.stack.fill")
                            .foregroundStyle(.white)
                        Text(context.attributes.deckName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 4) {
                        if context.state.remainingNew > 0 {
                            Text("\(context.state.remainingNew)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                        if context.state.remainingLearning > 0 {
                            Text("\(context.state.remainingLearning)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }
                        if context.state.remainingReview > 0 {
                            Text("\(context.state.remainingReview)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(cleanText(context.state.cardFront))
                            .font(.system(size: 16, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(.white)

                        if context.state.showingAnswer {
                            Text(cleanText(context.state.cardBack))
                                .font(.system(size: 14))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .padding(.horizontal, 8)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("Reviewed: \(context.state.totalReviewed)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Image(systemName: context.state.showingAnswer ? "eye.fill" : "eye.slash.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                }
            } compactLeading: {
                // Minimal leading view
                Image(systemName: "rectangle.stack.fill")
                    .foregroundStyle(.white)
            } compactTrailing: {
                // Minimal trailing view
                Text("\(context.state.totalReviewed)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            } minimal: {
                // Minimal view (pill shape)
                Image(systemName: "rectangle.stack.fill")
                    .foregroundStyle(.white)
            }
        }
    }

    private func cleanText(_ text: String) -> String {
        let cleaned = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        if cleaned.count > 50 {
            return String(cleaned.prefix(50)) + "..."
        }
        return cleaned
    }
}
