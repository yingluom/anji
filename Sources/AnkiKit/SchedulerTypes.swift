import Foundation

/// Opaque token wrapping serialized protobuf scheduling state bytes.
/// The app layer holds these tokens but never inspects them — only the
/// service layer serialises / deserialises them when talking to Rust.
public struct SchedulingStateToken: Sendable {
    package let bytes: Data
    package init(_ bytes: Data) { self.bytes = bytes }
}

/// The set of scheduling states returned by `getQueuedCards`.
/// Each token corresponds to the state the card would enter if the
/// user picked that rating.
public struct ReviewSchedulingStates: Sendable {
    public let current: SchedulingStateToken
    public let again: SchedulingStateToken
    public let hard: SchedulingStateToken
    public let good: SchedulingStateToken
    public let easy: SchedulingStateToken

    package init(
        current: SchedulingStateToken,
        again: SchedulingStateToken,
        hard: SchedulingStateToken,
        good: SchedulingStateToken,
        easy: SchedulingStateToken
    ) {
        self.current = current
        self.again = again
        self.hard = hard
        self.good = good
        self.easy = easy
    }
}

/// A single card from the review queue, bundled with its scheduling states
/// and pre-computed next-interval labels.
public struct QueuedReviewCard: Sendable {
    public let card: CardRecord
    public let states: ReviewSchedulingStates
    public let nextIntervals: [Rating: String]

    package init(
        card: CardRecord,
        states: ReviewSchedulingStates,
        nextIntervals: [Rating: String]
    ) {
        self.card = card
        self.states = states
        self.nextIntervals = nextIntervals
    }
}

/// Result of fetching the review queue for the current deck.
public struct QueuedCardsResult: Sendable {
    public let cards: [QueuedReviewCard]
    public let newCount: Int
    public let learningCount: Int
    public let reviewCount: Int

    package init(
        cards: [QueuedReviewCard],
        newCount: Int,
        learningCount: Int,
        reviewCount: Int
    ) {
        self.cards = cards
        self.newCount = newCount
        self.learningCount = learningCount
        self.reviewCount = reviewCount
    }
}

/// A rendered card with front and back HTML ready for display in a WebView.
public struct RenderedCard: Sendable {
    public let questionHTML: String
    public let answerHTML: String
    public let templateCSS: String

    package init(questionHTML: String, answerHTML: String, templateCSS: String = "") {
        self.questionHTML = questionHTML
        self.answerHTML = answerHTML
        self.templateCSS = templateCSS
    }
}
