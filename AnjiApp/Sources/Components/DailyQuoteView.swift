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
    @State private var quote: HitokotoResponse?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.title3)
                    .foregroundStyle(Color.anjiAccent.gradient)
                
                Spacer()
                
                Button {
                    fetchQuote()
                } label: {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(Color.anjiTertiary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            
            if isLoading && quote == nil {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.anjiTertiary.opacity(0.3))
                        .frame(height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.anjiTertiary.opacity(0.3))
                        .frame(width: 200, height: 16)
                }
                .padding(.vertical, 8)
            } else if let q = quote {
                Text(q.hitokoto)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(Color.anjiPrimary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Spacer()
                    Text("— \(q.author)")
                        .font(.caption)
                        .foregroundStyle(Color.anjiSecondary)
                }
            } else if error != nil {
                Text("quote.load_error")
                    .font(.caption)
                    .foregroundStyle(Color.anjiSecondary)
                    .onTapGesture { fetchQuote() }
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
