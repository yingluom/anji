import SwiftUI
import AnkiKit
import AnkiClients
import AnkiProto
import Dependencies
import SwiftProtobuf

/// View model for statistics, parsing the protobuf GraphsResponse.
@MainActor
@Observable
final class StatsViewModel {
    @ObservationIgnored @Dependency(\.statsClient) private var statsClient

    var isLoading = true
    var errorMessage: String?

    // Parsed data
    var today: TodayStats?
    var cardCounts: CardCountsData?
    var forecast: [ForecastPoint] = []
    var reviews: [ReviewPoint] = []
    var intervals: [IntervalPoint] = []
    var eases: [EasePoint] = []
    
    // New stats
    var hourlyData: [HourlyPoint] = []
    var stabilityData: [StabilityPoint] = []
    var difficultyData: [DifficultyPoint] = []
    var retrievabilityData: [RetrievabilityPoint] = []
    var trueRetention: TrueRetentionStats?

    var selectedRange: StatsRange = .oneMonth

    enum StatsRange: String, CaseIterable {
        case oneMonth = "1M"
        case threeMonths = "3M"
        case oneYear = "1Y"
        case allTime = "All"

        var days: UInt32 {
            switch self {
            case .oneMonth:      30
            case .threeMonths:   90
            case .oneYear:      365
            case .allTime:      3650 // ~10 years
            }
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            let data = try statsClient.fetchGraphs("deck:*", selectedRange.days)
            let response = try Anki_Stats_GraphsResponse(serializedBytes: data)
            parse(response)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func parse(_ response: Anki_Stats_GraphsResponse) {
        // Today stats
        if response.hasToday {
            let t = response.today
            today = TodayStats(
                studiedCards: Int(t.answerCount),
                studyTimeSecs: Int(t.answerMillis / 1000),
                correctCount: Int(t.correctCount),
                matureCorrect: Int(t.matureCorrect),
                matureCount: Int(t.matureCount),
                learnCount: Int(t.learnCount),
                reviewCount: Int(t.reviewCount),
                relearnCount: Int(t.relearnCount)
            )
        }

        // Card counts
        if response.hasCardCounts {
            let c = response.cardCounts.excludingInactive
            cardCounts = CardCountsData(
                newCards: Int(c.newCards),
                learn: Int(c.learn),
                young: Int(c.young),
                mature: Int(c.mature),
                suspended: Int(c.suspended),
                buried: Int(c.buried)
            )
        }

        // Forecast (future due)
        forecast = response.futureDue.futureDue.sorted { $0.key < $1.key }.map {
            ForecastPoint(dayOffset: Int($0.key), count: Int($0.value))
        }

        // Reviews (daily counts)
        if response.hasReviews {
            reviews = response.reviews.count.sorted { $0.key < $1.key }.map { entry in
                ReviewPoint(
                    dayOffset: Int(entry.key),
                    learn: Int(entry.value.learn),
                    review: Int(entry.value.young) + Int(entry.value.mature),
                    relearn: Int(entry.value.relearn),
                    filtered: Int(entry.value.filtered)
                )
            }
        }

        // Intervals (bucketed by days)
        intervals = response.intervals.intervals.sorted { $0.key < $1.key }.map {
            IntervalPoint(intervalDays: Int($0.key), count: Int($0.value))
        }

        // Ease (per-mille, 2500 = 250% but Anki stores as per-mille)
        eases = response.eases.eases.sorted { $0.key < $1.key }.map {
            EasePoint(easePercent: Double($0.key) / 10.0, count: Int($0.value))
        }
        
        // Hourly distribution (use selected range)
        if response.hasHours {
            let hoursData: [Anki_Stats_GraphsResponse.Hours.Hour]
            switch selectedRange {
            case .oneMonth: hoursData = Array(response.hours.oneMonth)
            case .threeMonths: hoursData = Array(response.hours.threeMonths)
            case .oneYear: hoursData = Array(response.hours.oneYear)
            case .allTime: hoursData = Array(response.hours.allTime)
            }
            hourlyData = hoursData.enumerated().map { hour, data in
                HourlyPoint(hour: hour, total: Int(data.total), correct: Int(data.correct))
            }
        }
        
        // Stability distribution (FSRS only)
        if response.hasStability {
            stabilityData = response.stability.intervals.sorted { $0.key < $1.key }.map {
                StabilityPoint(stabilityDays: Int($0.key), count: Int($0.value))
            }
        }
        
        // Difficulty distribution (FSRS only)
        if response.hasDifficulty {
            difficultyData = response.difficulty.eases.sorted { $0.key < $1.key }.map {
                DifficultyPoint(difficulty: Double($0.key) / 10.0, count: Int($0.value))
            }
        }
        
        // Retrievability (memory retention) - FSRS only
        if response.hasRetrievability {
            retrievabilityData = response.retrievability.retrievability.sorted { $0.key < $1.key }.map {
                RetrievabilityPoint(retrievabilityPercent: Double($0.key) / 10.0, count: Int($0.value))
            }
        }
        
        // True retention stats
        if response.hasTrueRetention {
            let tr = response.trueRetention
            trueRetention = TrueRetentionStats(
                today: parseRetention(tr.today),
                yesterday: parseRetention(tr.yesterday),
                week: parseRetention(tr.week),
                month: parseRetention(tr.month),
                year: parseRetention(tr.year),
                allTime: parseRetention(tr.allTime)
            )
        }
    }
    
    private func parseRetention(_ retention: Anki_Stats_GraphsResponse.TrueRetentionStats.TrueRetention) -> TrueRetention {
        TrueRetention(
            youngPassed: Int(retention.youngPassed),
            youngFailed: Int(retention.youngFailed),
            maturePassed: Int(retention.maturePassed),
            matureFailed: Int(retention.matureFailed)
        )
    }
}

// MARK: - Data Models

struct TodayStats {
    let studiedCards: Int
    let studyTimeSecs: Int
    let correctCount: Int
    let matureCorrect: Int
    let matureCount: Int
    let learnCount: Int
    let reviewCount: Int
    let relearnCount: Int

    var accuracy: Double {
        studiedCards > 0 ? Double(correctCount) / Double(studiedCards) : 0
    }

    var matureAccuracy: Double {
        matureCount > 0 ? Double(matureCorrect) / Double(matureCount) : 0
    }

    var formattedTime: String {
        let mins = studyTimeSecs / 60
        let secs = studyTimeSecs % 60
        return mins > 0 ? "\(mins)m \(secs)s" : "\(secs)s"
    }
}

struct ForecastPoint: Identifiable {
    let id = UUID()
    let dayOffset: Int
    let count: Int
    var date: Date {
        Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
    }
}

struct ReviewPoint: Identifiable {
    let id = UUID()
    let dayOffset: Int
    let learn: Int
    let review: Int
    let relearn: Int
    let filtered: Int
    var total: Int { learn + review + relearn + filtered }
    var date: Date {
        Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
    }
}

struct IntervalPoint: Identifiable {
    let id = UUID()
    let intervalDays: Int
    let count: Int
}

struct EasePoint: Identifiable {
    let id = UUID()
    let easePercent: Double // 130.0 = 130%
    let count: Int
}

// MARK: - New Stats Data Models

struct HourlyPoint: Identifiable {
    let id = UUID()
    let hour: Int // 0-23
    let total: Int
    let correct: Int
    var accuracy: Double { total > 0 ? Double(correct) / Double(total) : 0 }
}

struct StabilityPoint: Identifiable {
    let id = UUID()
    let stabilityDays: Int
    let count: Int
}

struct DifficultyPoint: Identifiable {
    let id = UUID()
    let difficulty: Double // 0-100%
    let count: Int
}

struct RetrievabilityPoint: Identifiable {
    let id = UUID()
    let retrievabilityPercent: Double // 0-100%
    let count: Int
}

struct TrueRetention {
    let youngPassed: Int
    let youngFailed: Int
    let maturePassed: Int
    let matureFailed: Int
    
    var youngTotal: Int { youngPassed + youngFailed }
    var matureTotal: Int { maturePassed + matureFailed }
    var youngRate: Double { youngTotal > 0 ? Double(youngPassed) / Double(youngTotal) : 0 }
    var matureRate: Double { matureTotal > 0 ? Double(maturePassed) / Double(matureTotal) : 0 }
}

struct TrueRetentionStats {
    let today: TrueRetention
    let yesterday: TrueRetention
    let week: TrueRetention
    let month: TrueRetention
    let year: TrueRetention
    let allTime: TrueRetention
}
