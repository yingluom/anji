import Foundation

/// Aggregated stats parsed from the Rust backend's GraphsResponse.
public struct CollectionStats: Sendable {
    public var totalCards: Int
    public var totalNotes: Int
    public var reviewsToday: Int
    public var minutesToday: Double
    public var streak: Int
    public var retentionRate: Double
    public var matureRetention: Double

    /// Daily review counts keyed by days-ago (0 = today).
    public var dailyReviews: [Int: Int]
    /// Hourly review counts (0–23).
    public var hourlyBreakdown: [Int: Int]

    public init(
        totalCards: Int = 0, totalNotes: Int = 0,
        reviewsToday: Int = 0, minutesToday: Double = 0,
        streak: Int = 0, retentionRate: Double = 0,
        matureRetention: Double = 0,
        dailyReviews: [Int: Int] = [:],
        hourlyBreakdown: [Int: Int] = [:]
    ) {
        self.totalCards = totalCards
        self.totalNotes = totalNotes
        self.reviewsToday = reviewsToday
        self.minutesToday = minutesToday
        self.streak = streak
        self.retentionRate = retentionRate
        self.matureRetention = matureRetention
        self.dailyReviews = dailyReviews
        self.hourlyBreakdown = hourlyBreakdown
    }
}
