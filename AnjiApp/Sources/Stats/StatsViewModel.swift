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
    var forecast: [ForecastPoint] = []
    var reviews: [ReviewPoint] = []
    var intervals: [IntervalPoint] = []
    var eases: [EasePoint] = []

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
