import SwiftUI
import AnkiKit
import AnkiServices
import Dependencies
import Foundation

@Observable @MainActor
final class ReviewSession {
    let deckId: Int64

    @ObservationIgnored @Dependency(\.decksService) var decks
    @ObservationIgnored @Dependency(\.schedulerService) var scheduler
    @ObservationIgnored @Dependency(\.cardRenderingService) var rendering
    @ObservationIgnored @Dependency(\.collectionService) var collection

    private(set) var questionHTML = ""
    private(set) var answerHTML = ""
    private(set) var showingAnswer = false
    private(set) var stats = SessionStats()
    private(set) var remainingCounts: DeckCounts = .zero
    private(set) var isFinished = false
    private(set) var canUndo = false
    private(set) var nextIntervals: [Rating: String] = [:]

    private var cardQueue: [QueuedReviewCard] = []
    private var currentCard: QueuedReviewCard?
    private var cardStartTime: Date = .now
    private var lastRating: Rating?

    init(deckId: Int64) { self.deckId = deckId }

    func start() {
        do {
            try decks.setCurrentDeck(deckId)
            reloadQueue()
            advanceToNext()
        } catch {
            isFinished = true
        }
    }

    func revealAnswer() { showingAnswer = true }

    func answer(rating: Rating) {
        guard let card = currentCard else { return }
        let elapsed = UInt32(Date.now.timeIntervalSince(cardStartTime) * 1000)

        do {
            try scheduler.answerCard(card.card.id, rating, elapsed, card.states)
            stats.reviewed += 1
            if rating != .again { stats.correct += 1 }
            stats.totalTimeMs += Int(elapsed)
            lastRating = rating
            canUndo = true

            reloadQueue()
            advanceToNext()
        } catch {
            if !cardQueue.isEmpty { cardQueue.removeFirst() }
            advanceToNext()
        }
    }

    func undo() {
        guard canUndo else { return }
        do {
            // Stop any playing audio first
            NotificationCenter.default.post(name: .init("AnjiStopAudio"), object: nil)

            try collection.undoLast()
            canUndo = false
            stats.reviewed -= 1
            if let r = lastRating, r != .again { stats.correct -= 1 }
            lastRating = nil

            // Reload queue to get the undone card back
            reloadQueue()

            // Reset to show the first card (the undone one) as question
            showingAnswer = false
            advanceToNext()
        } catch {
            // Silent fail - undo not available
        }
    }

    // MARK: Private

    private func reloadQueue() {
        guard let result = try? scheduler.getQueuedCards(200) else { return }
        cardQueue = result.cards
        remainingCounts = DeckCounts(
            newCount: result.newCount,
            learnCount: result.learningCount,
            reviewCount: result.reviewCount
        )
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

        if let rendered = try? rendering.renderCard(next.card.id) {
            questionHTML = rendered.questionHTML
            answerHTML = rendered.answerHTML
        } else {
            questionHTML = "<p style='color:red'>Failed to render card</p>"
            answerHTML = questionHTML
        }
    }
}
