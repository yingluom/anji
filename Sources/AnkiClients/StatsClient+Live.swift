import AnkiServices
public import Dependencies

extension StatsClient: DependencyKey {
    public static let liveValue: Self = {
        @Dependency(\.statsService) var stats
        return Self(
            fetchGraphs: { try stats.fetchGraphs($0, $1) }
        )
    }()
}
