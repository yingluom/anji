public import AnkiKit
public import Dependencies
import DependenciesMacros

@DependencyClient
public struct CardClient: Sendable {
    public var fetchDue: @Sendable (_ deckId: Int64) throws -> [CardRecord]
    public var answer: @Sendable (
        _ cardId: Int64, _ rating: Rating, _ timeSpentMs: UInt32,
        _ states: ReviewSchedulingStates
    ) throws -> Void
}

extension CardClient: TestDependencyKey {
    public static let testValue = CardClient()
}

extension DependencyValues {
    public var cardClient: CardClient {
        get { self[CardClient.self] }
        set { self[CardClient.self] = newValue }
    }
}
