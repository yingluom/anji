import ActivityKit
import SwiftUI
import AnkiKit

/// Live Activity attributes for Anji study session
/// Note: The Widget UI (ActivityConfiguration, DynamicIsland) must be defined
/// in a separate Widget Extension target. This file only contains the attributes
/// and manager for use in the main app.
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

// MARK: - Widget Extension
// Note: Live Activity Widget configuration (ActivityConfiguration, DynamicIsland)
// must be defined in a separate Widget Extension target, not the main app.
// This file only contains the ActivityAttributes and manager for use in the main app.
//
// To add Live Activity UI, create a new Widget Extension target and add:
//
// @main
// struct AnjiWidgetExtension: WidgetBundle {
//     var body: some Widget {
//         AnjiLiveActivityWidget()
//     }
// }
//
// struct AnjiLiveActivityWidget: Widget {
//     var body: some WidgetConfiguration {
//         ActivityConfiguration(for: AnjiStudyAttributes.self) { context in
//             // Lock screen view
//         } dynamicIsland: { context in
//             // Dynamic Island view
//         }
//     }
// }
