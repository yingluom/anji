import AnkiBackend
import AnkiProto
public import AnkiKit
public import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct DecksService: Sendable {
    public var fetchAll: @Sendable () throws -> [DeckInfo]
    public var fetchTree: @Sendable () throws -> [DeckTreeNode]
    public var countsForDeck: @Sendable (_ deckId: Int64) throws -> DeckCounts
    public var setCurrentDeck: @Sendable (_ deckId: Int64) throws -> Void
    public var getCurrentDeck: @Sendable () throws -> DeckInfo
    public var createDeck: @Sendable (_ name: String) throws -> Int64
    public var renameDeck: @Sendable (_ deckId: Int64, _ newName: String) throws -> Void
    public var removeDeck: @Sendable (_ deckId: Int64) throws -> Void
}

extension DecksService: DependencyKey {
    public static let liveValue: Self = {
        @Dependency(\.ankiBackend) var backend
        return Self(
            fetchAll: {
                var req = Anki_Decks_DeckTreeRequest()
                req.now = Int64(Date().timeIntervalSince1970)
                do {
                    let tree: Anki_Decks_DeckTreeNode = try backend.invoke(
                        service: AnkiBackend.Service.decks,
                        method: AnkiBackend.DecksMethod.getDeckTree,
                        request: req
                    )
                    return flattenTree(tree).sorted { $0.name < $1.name }
                } catch {
                    // Fallback: fetch names without counts
                    let resp: Anki_Decks_DeckNames = try backend.invoke(
                        service: AnkiBackend.Service.decks,
                        method: AnkiBackend.DecksMethod.getDeckNames,
                        request: Anki_Decks_GetDeckNamesRequest()
                    )
                    return resp.entries
                        .map { DeckInfo(id: $0.id, name: $0.name) }
                        .sorted { $0.name < $1.name }
                }
            },
            fetchTree: {
                var req = Anki_Decks_DeckTreeRequest()
                req.now = Int64(Date().timeIntervalSince1970)
                let tree: Anki_Decks_DeckTreeNode = try backend.invoke(
                    service: AnkiBackend.Service.decks,
                    method: AnkiBackend.DecksMethod.getDeckTree,
                    request: req
                )
                return tree.children.map { buildTreeNode($0) }
            },
            countsForDeck: { deckId in
                var req = Anki_Decks_DeckTreeRequest()
                req.now = Int64(Date().timeIntervalSince1970)
                do {
                    let tree: Anki_Decks_DeckTreeNode = try backend.invoke(
                        service: AnkiBackend.Service.decks,
                        method: AnkiBackend.DecksMethod.getDeckTree,
                        request: req
                    )
                    if let node = findNode(in: tree, deckId: deckId) {
                        return DeckCounts(
                            newCount: Int(node.newCount),
                            learnCount: Int(node.learnCount),
                            reviewCount: Int(node.reviewCount)
                        )
                    }
                } catch {}
                return .zero
            },
            setCurrentDeck: { deckId in
                var req = Anki_Decks_DeckId()
                req.did = deckId
                try backend.invokeVoid(
                    service: AnkiBackend.Service.decks,
                    method: AnkiBackend.DecksMethod.setCurrentDeck,
                    request: req
                )
            },
            getCurrentDeck: {
                let deck: Anki_Decks_Deck = try backend.invoke(
                    service: AnkiBackend.Service.decks,
                    method: AnkiBackend.DecksMethod.getCurrentDeck,
                    request: Anki_Generic_Empty()
                )
                return DeckInfo(id: deck.id, name: deck.name)
            },
            createDeck: { name in
                var deck: Anki_Decks_Deck = try backend.invoke(
                    service: AnkiBackend.Service.decks,
                    method: AnkiBackend.DecksMethod.newDeck
                )
                deck.name = name
                let resp: Anki_Collection_OpChangesWithId = try backend.invoke(
                    service: AnkiBackend.Service.decks,
                    method: AnkiBackend.DecksMethod.addDeck,
                    request: deck
                )
                return resp.id
            },
            renameDeck: { deckId, newName in
                var req = Anki_Decks_RenameDeckRequest()
                req.deckID = deckId
                req.newName = newName
                try backend.invokeVoid(
                    service: AnkiBackend.Service.decks,
                    method: AnkiBackend.DecksMethod.renameDeck,
                    request: req
                )
            },
            removeDeck: { deckId in
                var req = Anki_Decks_DeckIds()
                req.dids = [deckId]
                try backend.invokeVoid(
                    service: AnkiBackend.Service.decks,
                    method: AnkiBackend.DecksMethod.removeDecks,
                    request: req
                )
            }
        )
    }()
}

extension DecksService: TestDependencyKey {
    public static let testValue = DecksService()
}

extension DependencyValues {
    public var decksService: DecksService {
        get { self[DecksService.self] }
        set { self[DecksService.self] = newValue }
    }
}

// MARK: - Tree Helpers

private func flattenTree(_ node: Anki_Decks_DeckTreeNode, parent: String = "") -> [DeckInfo] {
    var result: [DeckInfo] = []
    for child in node.children {
        let path = parent.isEmpty ? child.name : "\(parent)::\(child.name)"
        result.append(DeckInfo(
            id: child.deckID,
            name: path,
            counts: DeckCounts(
                newCount: Int(child.newCount),
                learnCount: Int(child.learnCount),
                reviewCount: Int(child.reviewCount)
            )
        ))
        result.append(contentsOf: flattenTree(child, parent: path))
    }
    return result
}

private func findNode(in node: Anki_Decks_DeckTreeNode, deckId: Int64) -> Anki_Decks_DeckTreeNode? {
    if node.deckID == deckId { return node }
    for child in node.children {
        if let found = findNode(in: child, deckId: deckId) { return found }
    }
    return nil
}

private func buildTreeNode(_ node: Anki_Decks_DeckTreeNode, parent: String = "") -> DeckTreeNode {
    let fullPath = parent.isEmpty ? node.name : "\(parent)::\(node.name)"
    return DeckTreeNode(
        id: node.deckID,
        name: node.name,
        fullName: fullPath,
        counts: DeckCounts(
            newCount: Int(node.newCount),
            learnCount: Int(node.learnCount),
            reviewCount: Int(node.reviewCount)
        ),
        children: node.children.map { buildTreeNode($0, parent: fullPath) }
    )
}
