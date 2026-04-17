import AnkiBackend
import AnkiProto
public import AnkiKit
public import Dependencies
import DependenciesMacros
import Foundation
import SwiftProtobuf

@DependencyClient
public struct SchedulerService: Sendable {
    /// Fetch the review queue for the current deck.
    public var getQueuedCards: @Sendable (_ fetchLimit: Int32) throws -> QueuedCardsResult

    /// Answer a card using the scheduling states from `getQueuedCards`.
    public var answerCard: @Sendable (
        _ cardId: Int64, _ rating: Rating, _ timeSpentMs: UInt32,
        _ states: ReviewSchedulingStates
    ) throws -> Void
}

extension SchedulerService: DependencyKey {
    public static let liveValue: Self = {
        @Dependency(\.ankiBackend) var backend
        return Self(
            getQueuedCards: { fetchLimit in
                var req = Anki_Scheduler_GetQueuedCardsRequest()
                req.fetchLimit = UInt32(fetchLimit)
                let response: Anki_Scheduler_QueuedCards = try backend.invoke(
                    service: AnkiBackend.Service.scheduler,
                    method: AnkiBackend.SchedulerMethod.getQueuedCards,
                    request: req
                )

                let cards: [QueuedReviewCard] = try response.cards.compactMap { queued in
                    guard queued.hasCard else { return nil }

                    let states = ReviewSchedulingStates(
                        current: SchedulingStateToken(try queued.states.current.serializedData()),
                        again:   SchedulingStateToken(try queued.states.again.serializedData()),
                        hard:    SchedulingStateToken(try queued.states.hard.serializedData()),
                        good:    SchedulingStateToken(try queued.states.good.serializedData()),
                        easy:    SchedulingStateToken(try queued.states.easy.serializedData())
                    )

                    let intervals: [Rating: String] = [
                        .again: formatInterval(scheduledSecs(queued.states.again)),
                        .hard:  formatInterval(scheduledSecs(queued.states.hard)),
                        .good:  formatInterval(scheduledSecs(queued.states.good)),
                        .easy:  formatInterval(scheduledSecs(queued.states.easy)),
                    ]

                    return QueuedReviewCard(
                        card: mapCard(queued.card),
                        states: states,
                        nextIntervals: intervals
                    )
                }

                return QueuedCardsResult(
                    cards: cards,
                    newCount: Int(response.newCount),
                    learningCount: Int(response.learningCount),
                    reviewCount: Int(response.reviewCount)
                )
            },
            answerCard: { cardId, rating, timeSpentMs, states in
                let currentState = try Anki_Scheduler_SchedulingState(
                    serializedBytes: states.current.bytes
                )
                let newStateBytes: Data = switch rating {
                case .again: states.again.bytes
                case .hard:  states.hard.bytes
                case .good:  states.good.bytes
                case .easy:  states.easy.bytes
                }
                let newState = try Anki_Scheduler_SchedulingState(
                    serializedBytes: newStateBytes
                )

                var answer = Anki_Scheduler_CardAnswer()
                answer.cardID = cardId
                answer.currentState = currentState
                answer.newState = newState
                answer.rating = protoRating(rating)
                answer.answeredAtMillis = Int64(Date().timeIntervalSince1970 * 1000)
                answer.millisecondsTaken = timeSpentMs

                try backend.invokeVoid(
                    service: AnkiBackend.Service.scheduler,
                    method: AnkiBackend.SchedulerMethod.answerCard,
                    request: answer
                )
            }
        )
    }()
}

extension SchedulerService: TestDependencyKey {
    public static let testValue = SchedulerService()
}

extension DependencyValues {
    public var schedulerService: SchedulerService {
        get { self[SchedulerService.self] }
        set { self[SchedulerService.self] = newValue }
    }
}

// MARK: - Helpers

private func protoRating(_ r: Rating) -> Anki_Scheduler_CardAnswer.Rating {
    switch r {
    case .again: .again
    case .hard:  .hard
    case .good:  .good
    case .easy:  .easy
    }
}

private func mapCard(_ c: Anki_Cards_Card) -> CardRecord {
    CardRecord(
        id: c.id, noteId: c.noteID, deckId: c.deckID,
        templateIndex: Int32(c.templateIdx), modifiedAt: c.mtimeSecs,
        usn: c.usn, cardType: Int16(c.ctype), queue: Int16(c.queue),
        due: c.due, interval: Int32(c.interval), easeFactor: Int32(c.easeFactor),
        reps: Int32(c.reps), lapses: Int32(c.lapses),
        remainingSteps: Int32(c.remainingSteps), originalDue: c.originalDue,
        originalDeckId: c.originalDeckID, flags: Int32(c.flags),
        customData: c.customData
    )
}

private func scheduledSecs(_ state: Anki_Scheduler_SchedulingState) -> UInt32 {
    switch state.kind {
    case .normal(let n): normalScheduledSecs(n)
    case .filtered, .none: 0
    }
}

private func normalScheduledSecs(_ n: Anki_Scheduler_SchedulingState.Normal) -> UInt32 {
    switch n.kind {
    case .new:             0
    case .learning(let s): s.scheduledSecs
    case .review(let s):   s.scheduledDays * 86400
    case .relearning(let s): s.learning.scheduledSecs
    case .none:            0
    }
}

private func formatInterval(_ secs: UInt32) -> String {
    if secs < 60 { return "\(secs)s" }
    let mins = secs / 60
    if mins < 60 { return "\(mins)m" }
    let hours = mins / 60
    if hours < 24 { return "\(hours)h" }
    let days = hours / 24
    if days < 30 { return "\(days)d" }
    let months = days / 30
    if months < 12 { return "\(months)mo" }
    return String(format: "%.1fy", Double(days) / 365.0)
}
