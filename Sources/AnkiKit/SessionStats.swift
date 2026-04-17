import Foundation

/// Tracks review performance within a single study session.
public struct SessionStats: Sendable {
    public var reviewed: Int = 0
    public var correct: Int = 0
    public var totalTimeMs: Int = 0

    public init() {}

    /// Fraction of cards answered correctly (not "Again"). Returns 0 if none reviewed.
    public var accuracy: Double {
        reviewed > 0 ? Double(correct) / Double(reviewed) : 0
    }

    /// Average seconds per card.
    public var averageTimePerCard: Double {
        reviewed > 0 ? Double(totalTimeMs) / 1000.0 / Double(reviewed) : 0
    }
}
