import AnkiKit
import AnkiServices
public import Dependencies

extension DeckClient: DependencyKey {
    public static let liveValue: Self = {
        @Dependency(\.decksService) var decks
        return Self(
            fetchAll:      { try decks.fetchAll() },
            fetchTree:     { try decks.fetchTree() },
            countsForDeck: { try decks.countsForDeck($0) },
            create:        { try decks.createDeck($0) },
            rename:        { try decks.renameDeck($0, $1) },
            delete:        { try decks.removeDeck($0) }
        )
    }()
}
