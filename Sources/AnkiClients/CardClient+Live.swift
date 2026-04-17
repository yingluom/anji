import AnkiKit
import AnkiServices
public import Dependencies

extension CardClient: DependencyKey {
    public static let liveValue: Self = {
        @Dependency(\.schedulerService) var scheduler
        @Dependency(\.decksService) var decks
        return Self(
            fetchDue: { deckId in
                try decks.setCurrentDeck(deckId)
                let result = try scheduler.getQueuedCards(200)
                return result.cards.map(\.card)
            },
            answer: { cardId, rating, timeSpentMs, states in
                try scheduler.answerCard(cardId, rating, timeSpentMs, states)
            }
        )
    }()
}
