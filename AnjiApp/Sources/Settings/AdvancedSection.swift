import SwiftUI
import Sharing

/// Advanced settings — sync options, Live Activity, daily quote, etc.
struct AdvancedSection: View {
    @Shared(.autoSync) private var autoSync
    @Shared(.wifiOnlySync) private var wifiOnlySync
    @Shared(.liveActivityEnabled) private var liveActivityEnabled
    @Shared(.dailyQuoteEnabled) private var dailyQuoteEnabled
    @Shared(.homeStatCards) private var homeStatCards
    
    private let availableStatCards = [
        ("today", "今日统计", "chart.bar"),
        ("cardCounts", "卡片数量", "number"),
        ("forecast", "未来预测", "calendar"),
        ("reviews", "复习统计", "chart.line.uptrend.xyaxis"),
        ("retention", "保留率", "brain.head.profile")
    ]

    var body: some View {
        Section {
            Toggle(isOn: Binding($autoSync)) {
                Label("settings.auto_sync", systemImage: "arrow.clockwise.circle")
            }

            Toggle(isOn: Binding($wifiOnlySync)) {
                Label("settings.wifi_only", systemImage: "wifi")
            }

            if #available(iOS 16.1, *) {
                Toggle(isOn: Binding($liveActivityEnabled)) {
                    Label("settings.live_activity", systemImage: "island.2")
                }
            }
        } header: {
            Text("settings.section.advanced")
        }
        
        Section {
            Toggle(isOn: Binding($dailyQuoteEnabled)) {
                Label("settings.daily_quote", systemImage: "quote.bubble")
            }
        } header: {
            Text("settings.section.home_display")
        } footer: {
            Text("settings.daily_quote.footer")
        }
        
        Section {
            ForEach(availableStatCards, id: \.0) { card in
                Toggle(isOn: Binding(
                    get: { isStatCardEnabled(card.0) },
                    set: { toggleStatCard(card.0, enabled: $0) }
                )) {
                    Label(card.1, systemImage: card.2)
                }
            }
        } header: {
            Text("settings.section.home_stats")
        } footer: {
            Text("settings.home_stats.footer")
        }
    }
    
    private func isStatCardEnabled(_ cardId: String) -> Bool {
        Array(homeStatCards.split(separator: ",")).map(String.init).contains(cardId)
    }
    
    private func toggleStatCard(_ cardId: String, enabled: Bool) {
        var cards = Array(homeStatCards.split(separator: ",")).map(String.init)
        if enabled {
            if !cards.contains(cardId) {
                cards.append(cardId)
            }
        } else {
            cards.removeAll { $0 == cardId }
        }
        $homeStatCards.withLock { $0 = cards.joined(separator: ",") }
    }
}
