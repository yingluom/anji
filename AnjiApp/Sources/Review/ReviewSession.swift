import SwiftUI
import AnkiKit
import AnkiServices
import Dependencies
import Foundation

/// The type of card being reviewed, for UI display purposes.
enum CardQueueType: String, CaseIterable {
    case new = "new"
    case learning = "learning"
    case review = "review"
    case unknown = "unknown"

    var label: String {
        switch self {
        case .new: return String(localized: "card.type.new")
        case .learning: return String(localized: "card.type.learning")
        case .review: return String(localized: "card.type.review")
        case .unknown: return ""
        }
    }

    var color: Color {
        switch self {
        case .new: return .anjiNew
        case .learning: return .anjiLearn
        case .review: return .anjiReview
        case .unknown: return .gray
        }
    }
}

@Observable @MainActor
final class ReviewSession {
    let deckId: Int64

    @ObservationIgnored @Dependency(\.decksService) var decks
    @ObservationIgnored @Dependency(\.schedulerService) var scheduler
    @ObservationIgnored @Dependency(\.cardRenderingService) var rendering
    @ObservationIgnored @Dependency(\.collectionService) var collection

    private(set) var questionHTML = ""
    private(set) var answerHTML = ""
    private(set) var templateCSS = ""
    private(set) var showingAnswer = false
    private(set) var stats = SessionStats()
    private(set) var remainingCounts: DeckCounts = .zero
    private(set) var isFinished = false
    private(set) var canUndo = false
    private(set) var nextIntervals: [Rating: String] = [:]
    /// Last error encountered during session operations, exposed for UI diagnostics.
    private(set) var lastError: String?

    /// Current card type: new (blue), learning (red), or review (green)
    var currentCardType: CardQueueType {
        guard let card = currentCard?.card else { return .unknown }
        // queue: 0=new, 1=learning, 2=review
        switch card.queue {
        case 0: return .new
        case 1: return .learning
        case 2: return .review
        default: return .unknown
        }
    }

    private var cardQueue: [QueuedReviewCard] = []
    private var currentCard: QueuedReviewCard?
    private var cardStartTime: Date = .now
    private var lastRating: Rating?
    private var lastCardId: Int64?

    init(deckId: Int64) { self.deckId = deckId }

    func start() {
        do {
            try decks.setCurrentDeck(deckId)
        } catch {
            lastError = "Failed to set current deck: \(error)"
            isFinished = true
            return
        }

        reloadQueue()
        advanceToNext()
    }

    func revealAnswer() { showingAnswer = true }

    func answer(rating: Rating) {
        guard let card = currentCard else { return }
        let elapsed = UInt32(Date.now.timeIntervalSince(cardStartTime) * 1000)

        do {
            // Save current card ID before answering (for undo)
            lastCardId = card.card.id
            
            try scheduler.answerCard(card.card.id, rating, elapsed, card.states)
            stats.reviewed += 1
            if rating != .again { stats.correct += 1 }
            stats.totalTimeMs += Int(elapsed)
            lastRating = rating
            canUndo = true

            reloadQueue()
            advanceToNext()
        } catch {
            lastError = "Answer failed: \(error)"
            if !cardQueue.isEmpty { cardQueue.removeFirst() }
            advanceToNext()
        }
    }

    func undo() {
        guard canUndo else { return }
        do {
            // Stop any playing audio first
            NotificationCenter.default.post(name: .init("AnjiStopAudio"), object: nil)

            // Perform the undo operation
            try collection.undoLast()
            
            // Update stats
            stats.reviewed -= 1
            if let r = lastRating, r != .again { stats.correct -= 1 }
            
            // Save the card ID we're trying to restore
            let targetCardId = lastCardId
            
            // Reset undo state
            canUndo = false
            lastRating = nil
            lastCardId = nil

            // Reload queue to get the undone card back
            reloadQueue()

            // Find and restore the undone card
            showingAnswer = false
            restoreCard(targetCardId)
        } catch {
            // Silent fail - undo not available
        }
    }

    // MARK: Private

    private func reloadQueue() {
        do {
            let result = try scheduler.getQueuedCards(200)
            cardQueue = result.cards
            remainingCounts = DeckCounts(
                newCount: result.newCount,
                learnCount: result.learningCount,
                reviewCount: result.reviewCount
            )
        } catch {
            lastError = "Failed to load cards: \(error)"
            cardQueue = []
        }
    }

    private func advanceToNext() {
        guard let next = cardQueue.first else {
            isFinished = true
            currentCard = nil
            return
        }
        currentCard = next
        showingAnswer = false
        cardStartTime = .now
        nextIntervals = next.nextIntervals

        do {
            let rendered = try rendering.renderCard(next.card.id)
            questionHTML = rendered.questionHTML
            answerHTML = rendered.answerHTML
            templateCSS = rendered.templateCSS
        } catch {
            lastError = "Render failed: \(error)"
            questionHTML = "<p style='color:red'>Failed to render card</p><p style='color:gray;font-size:12px'>Card ID: \(next.card.id)<br>Error: \(error)</p>"
            answerHTML = questionHTML
            templateCSS = ""
        }
    }

    /// Restore a specific card by ID from the queue (used by undo)
    private func restoreCard(_ cardId: Int64?) {
        guard let targetId = cardId else {
            // No target, just advance to next
            advanceToNext()
            return
        }
        
        // Find the card in queue
        if let index = cardQueue.firstIndex(where: { $0.card.id == targetId }) {
            // Move the card to the front of the queue
            let card = cardQueue.remove(at: index)
            cardQueue.insert(card, at: 0)
        }
        
        // Now show the first card (the undone one)
        advanceToNext()
    }
}
