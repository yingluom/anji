import SwiftUI

/// Daily inspirational quote widget for the home screen.
struct DailyQuoteView: View {
    @State private var quote: Quote?
    @State private var isLoading = false
    
    struct Quote: Identifiable {
        let id = UUID()
        let text: String
        let author: String
        let category: String
    }
    
    // Curated collection of motivational quotes for learning
    private let quotes: [Quote] = [
        Quote(text: "学习不是填满水桶，而是点燃火焰。", author: "威廉·巴特勒·叶芝", category: "learning"),
        Quote(text: "The expert in anything was once a beginner.", author: "Helen Hayes", category: "learning"),
        Quote(text: "每天进步一点点，一年后你会感谢今天的自己。", author: "佚名", category: "growth"),
        Quote(text: "Knowledge is power, but practice is the key.", author: "Anonymous", category: "practice"),
        Quote(text: "重复是记忆之母，理解是记忆之父。", author: "古罗马谚语", category: "memory"),
        Quote(text: "Learning is not attained by chance, it must be sought for with ardor.", author: "Abigail Adams", category: "learning"),
        Quote(text: "宝剑锋从磨砺出，梅花香自苦寒来。", author: "古诗", category: "perseverance"),
        Quote(text: "The beautiful thing about learning is that no one can take it away from you.", author: "B.B. King", category: "learning"),
        Quote(text: "学而时习之，不亦说乎？", author: "孔子", category: "practice"),
        Quote(text: "Small steps every day lead to big results.", author: "Anonymous", category: "growth"),
        Quote(text: "记忆是知识的唯一仓库。", author: "托马斯·富勒", category: "memory"),
        Quote(text: "It always seems impossible until it's done.", author: "Nelson Mandela", category: "perseverance"),
        Quote(text: "书山有路勤为径，学海无涯苦作舟。", author: "韩愈", category: "dedication"),
        Quote(text: "Success is the sum of small efforts repeated day in and day out.", author: "Robert Collier", category: "habit"),
        Quote(text: "温故而知新，可以为师矣。", author: "孔子", category: "review"),
        Quote(text: "Your future is created by what you do today, not tomorrow.", author: "Robert Kiyosaki", category: "action"),
        Quote(text: "熟能生巧，巧能生精。", author: "古语", category: "practice"),
        Quote(text: "Don't watch the clock; do what it does. Keep going.", author: "Sam Levenson", category: "persistence"),
        Quote(text: "学而不思则罔，思而不学则殆。", author: "孔子", category: "thinking"),
        Quote(text: "The more you sweat in practice, the less you bleed in battle.", author: "Richard Marcinko", category: "preparation")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.title3)
                    .foregroundStyle(Color.anjiAccent.gradient)
                
                Spacer()
                
                Button {
                    refreshQuote()
                } label: {
                    Image(systemName: "shuffle")
                        .font(.caption)
                        .foregroundStyle(Color.anjiTertiary)
                }
                .buttonStyle(.plain)
            }
            
            if let quote = quote {
                Text(quote.text)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(Color.anjiPrimary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Spacer()
                    Text("— \(quote.author)")
                        .font(.caption)
                        .foregroundStyle(Color.anjiSecondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.anjiAccent.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            loadDailyQuote()
        }
    }
    
    private func loadDailyQuote() {
        // Use the day of year as seed for consistent daily quote
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % quotes.count
        quote = quotes[index]
    }
    
    private func refreshQuote() {
        withAnimation(.easeInOut(duration: 0.3)) {
            var newQuote: Quote?
            repeat {
                newQuote = quotes.randomElement()
            } while newQuote?.text == quote?.text
            quote = newQuote
        }
    }
}

// MARK: - Preview

#Preview {
    DailyQuoteView()
        .padding()
        .background(Color.anjiBackground)
}
