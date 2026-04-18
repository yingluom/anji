import SwiftUI

/// Response from hitokoto.cn API
struct HitokotoResponse: Codable {
    let id: Int
    let uuid: String
    let hitokoto: String
    let type: String
    let from: String
    let from_who: String?
    let creator: String
    let created_at: String
    
    /// Get author name, preferring from_who, then from, then "佚名"
    var author: String {
        if let who = from_who, !who.isEmpty {
            return who
        }
        if !from.isEmpty {
            return from
        }
        return "佚名"
    }
}

/// Daily inspirational quote widget fetching from hitokoto.cn API.
struct DailyQuoteView: View {
    @Environment(\.anjiAccent) private var anjiAccent
    @State private var quote: HitokotoResponse?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        HStack(spacing: 10) {
            // Small quote icon
            Image(systemName: "quote.bubble")
                .font(.system(size: 12))
                .foregroundStyle(anjiAccent)
                .frame(width: 24, height: 24)
                .background(anjiAccent.opacity(0.1))
                .clipShape(Circle())

            // Quote content
            if isLoading && quote == nil {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.anjiTertiary.opacity(0.3))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.anjiTertiary.opacity(0.3))
                        .frame(width: 120, height: 10)
                }
            } else if let q = quote {
                VStack(alignment: .leading, spacing: 2) {
                    Text(q.hitokoto)
                        .font(.system(size: 13, design: .default))
                        .foregroundStyle(Color.anjiPrimary)
                        .lineLimit(1)

                    Text("— \(q.author)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.anjiTertiary)
                }
            } else if error != nil {
                Text("quote.load_error")
                    .font(.caption)
                    .foregroundStyle(Color.anjiSecondary)
                    .onTapGesture { fetchQuote() }
            }

            Spacer()

            // Refresh button
            Button {
                fetchQuote()
            } label: {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.anjiTertiary)
                }
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(anjiAccent.opacity(0.15), lineWidth: 0.5)
                )
        )
        .onAppear {
            if quote == nil {
                fetchQuote()
            }
        }
    }
    
    private func fetchQuote() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let url = URL(string: "https://v1.hitokoto.cn/?c=a&c=b&c=d&c=h&c=i&c=k&encode=json")!
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                
                let decoded = try JSONDecoder().decode(HitokotoResponse.self, from: data)
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        quote = decoded
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DailyQuoteView()
        .padding()
        .background(Color.anjiBackground)
}
