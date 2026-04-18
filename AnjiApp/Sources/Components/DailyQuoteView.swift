import SwiftUI
import Sharing

// MARK: - Quote Providers

enum QuoteProvider: String, CaseIterable, Sendable, Codable {
    case hitokoto = "一言"
    case jinrishici = "今日诗词"
    
    var icon: String {
        switch self {
        case .hitokoto: return "quote.bubble"
        case .jinrishici: return "text.book.closed"
        }
    }
}

/// 一言类型
enum HitokotoType: String, CaseIterable, Sendable, Codable {
    case anime = "a"      // 动画
    case comic = "b"      // 漫画
    case game = "c"       // 游戏
    case novel = "d"      // 小说
    case original = "e"   // 原创
    case internet = "f"   // 网络
    case other = "g"      // 其他
    case movie = "h"      // 影视
    case poetry = "i"     // 诗词
    case netease = "j"    // 网易云
    case philosophy = "k"   // 哲学
    case witty = "l"      // 抖机灵
    
    var displayName: String {
        switch self {
        case .anime: return "动画"
        case .comic: return "漫画"
        case .game: return "游戏"
        case .novel: return "小说"
        case .original: return "原创"
        case .internet: return "网络"
        case .other: return "其他"
        case .movie: return "影视"
        case .poetry: return "诗词"
        case .netease: return "网易云"
        case .philosophy: return "哲学"
        case .witty: return "抖机灵"
        }
    }
    
    var icon: String {
        switch self {
        case .anime: return "play.tv"
        case .comic: return "book.closed"
        case .game: return "gamecontroller"
        case .novel: return "text.book.closed"
        case .original: return "pencil"
        case .internet: return "globe"
        case .other: return "ellipsis"
        case .movie: return "film"
        case .poetry: return "text.quote"
        case .netease: return "music.note"
        case .philosophy: return "brain.head.profile"
        case .witty: return "face.smiling"
        }
    }
}

// MARK: - API Responses

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

/// Response from jinrishici.com API
struct JinrishiciResponse: Codable {
    let status: String
    let data: JinrishiciData
    
    struct JinrishiciData: Codable {
        let content: String
        let origin: JinrishiciOrigin
        
        struct JinrishiciOrigin: Codable {
            let title: String
            let dynasty: String
            let author: String
        }
    }
    
    var quoteText: String { data.content }
    var author: String { "\(data.origin.dynasty) · \(data.origin.author)「\(data.origin.title)」" }
}

// MARK: - Shared Keys

extension SharedReaderKey where Self == AppStorageKey<QuoteProvider>.Default {
    static var quoteProvider: Self {
        Self[.appStorage("quoteProvider"), default: .hitokoto]
    }
}

extension SharedReaderKey where Self == AppStorageKey<HitokotoType>.Default {
    static var hitokotoType: Self {
        Self[.appStorage("hitokotoType"), default: .poetry]
    }
}

// MARK: - View

/// Daily inspirational quote widget with multiple providers and types.
struct DailyQuoteView: View {
    @Environment(\.anjiAccent) private var anjiAccent
    @Shared(.quoteProvider) private var provider
    @Shared(.hitokotoType) private var hitokotoType
    
    @State private var quoteText: String = ""
    @State private var authorText: String = ""
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showTypePicker = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Provider selector row
            HStack(spacing: 8) {
                // Provider picker
                Menu {
                    ForEach(QuoteProvider.allCases, id: \.self) { p in
                        Button {
                            withAnimation {
                                provider = p
                                fetchQuote()
                            }
                        } label: {
                            Label(p.rawValue, systemImage: p.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: provider.icon)
                            .font(.system(size: 10))
                        Text(provider.rawValue)
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(anjiAccent.opacity(0.1))
                    .foregroundStyle(anjiAccent)
                    .clipShape(Capsule())
                }
                
                // Type picker (only for hitokoto)
                if provider == .hitokoto {
                    Menu {
                        ForEach(HitokotoType.allCases, id: \.self) { type in
                            Button {
                                withAnimation {
                                    hitokotoType = type
                                    fetchQuote()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: type.icon)
                                    Text(type.displayName)
                                    if hitokotoType == type {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: hitokotoType.icon)
                                .font(.system(size: 10))
                            Text(hitokotoType.displayName)
                                .font(.system(size: 11, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .foregroundStyle(Color.anjiSecondary)
                        .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                // Refresh button
                Button {
                    fetchQuote()
                } label: {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.anjiTertiary)
                            .frame(width: 28, height: 28)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            
            Divider()
                .opacity(0.5)
            
            // Quote content
            HStack(spacing: 10) {
                // Quote icon
                Image(systemName: provider == .jinrishici ? "text.book.closed" : "quote.bubble")
                    .font(.system(size: 14))
                    .foregroundStyle(anjiAccent)
                    .frame(width: 28, height: 28)
                    .background(anjiAccent.opacity(0.1))
                    .clipShape(Circle())
                
                // Content
                if isLoading && quoteText.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.anjiTertiary.opacity(0.3))
                            .frame(height: 12)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.anjiTertiary.opacity(0.3))
                            .frame(width: 100, height: 12)
                    }
                } else if !quoteText.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quoteText)
                            .font(.system(size: 14, design: provider == .jinrishici ? .serif : .default))
                            .foregroundStyle(Color.anjiPrimary)
                            .lineLimit(2)
                        
                        if !authorText.isEmpty {
                            Text("— \(authorText)")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.anjiTertiary)
                                .lineLimit(1)
                        }
                    }
                } else if error != nil {
                    Text("quote.load_error")
                        .font(.caption)
                        .foregroundStyle(Color.anjiSecondary)
                        .onTapGesture { fetchQuote() }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(anjiAccent.opacity(0.15), lineWidth: 0.5)
                )
        )
        .onAppear {
            if quoteText.isEmpty {
                fetchQuote()
            }
        }
        .onChange(of: provider) { _, _ in
            fetchQuote()
        }
    }
    
    private func fetchQuote() {
        isLoading = true
        error = nil
        
        Task {
            do {
                switch provider {
                case .hitokoto:
                    try await fetchHitokoto()
                case .jinrishici:
                    try await fetchJinrishici()
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
    
    private func fetchHitokoto() async throws {
        // Build URL with selected type
        let typeParam = hitokotoType.rawValue
        let url = URL(string: "https://v1.hitokoto.cn/?c=\(typeParam)&encode=json")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(HitokotoResponse.self, from: data)
        
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                quoteText = decoded.hitokoto
                authorText = decoded.author
                isLoading = false
            }
        }
    }
    
    private func fetchJinrishici() async throws {
        let url = URL(string: "https://v2.jinrishici.com/one.json")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(JinrishiciResponse.self, from: data)
        
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                quoteText = decoded.quoteText
                authorText = decoded.author
                isLoading = false
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
