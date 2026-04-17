import AnkiBackend
import AnkiProto
public import AnkiKit
public import Dependencies
import DependenciesMacros

@DependencyClient
public struct CardRenderingService: Sendable {
    /// Render a card's question and answer HTML for display in a WebView.
    public var renderCard: @Sendable (_ cardId: Int64) throws -> RenderedCard
}

extension CardRenderingService: DependencyKey {
    public static let liveValue: Self = {
        @Dependency(\.ankiBackend) var backend
        return Self(
            renderCard: { cardId in
                var req = Anki_CardRendering_RenderExistingCardRequest()
                req.cardID = cardId
                req.browser = false

                let rendered: Anki_CardRendering_RenderCardResponse = try backend.invoke(
                    service: AnkiBackend.Service.cardRendering,
                    method: AnkiBackend.CardRenderingMethod.renderExistingCard,
                    request: req
                )

                var questionHTML = renderNodes(rendered.questionNodes)
                var answerHTML = renderNodes(rendered.answerNodes)

                // Prepend CSS if present
                if !rendered.css.isEmpty {
                    let style = "<style>\(rendered.css)</style>"
                    questionHTML = style + questionHTML
                    answerHTML = style + answerHTML
                }

                return RenderedCard(questionHTML: questionHTML, answerHTML: answerHTML)
            }
        )
    }()
}

extension CardRenderingService: TestDependencyKey {
    public static let testValue = CardRenderingService()
}

extension DependencyValues {
    public var cardRenderingService: CardRenderingService {
        get { self[CardRenderingService.self] }
        set { self[CardRenderingService.self] = newValue }
    }
}

/// Convert rendered template nodes to HTML.
private func renderNodes(_ nodes: [Anki_CardRendering_RenderedTemplateNode]) -> String {
    nodes.map { node in
        switch node.value {
        case .text(let text):        text
        case .replacement(let r):    r.currentText
        case .none:                  ""
        }
    }.joined()
}
