import Testing
import AnkiKit

@Suite("AnkiKit Tests")
struct AnkiKitTests {

    @Test("Rating ordering")
    func ratingOrdering() {
        #expect(Rating.again < Rating.hard)
        #expect(Rating.hard  < Rating.good)
        #expect(Rating.good  < Rating.easy)
    }

    @Test("DeckCounts total and isEmpty")
    func deckCountsTotal() {
        let zero = DeckCounts.zero
        #expect(zero.total == 0)
        #expect(zero.isEmpty)

        let counts = DeckCounts(newCount: 3, learnCount: 2, reviewCount: 10)
        #expect(counts.total == 15)
        #expect(!counts.isEmpty)
    }

    @Test("SessionStats accuracy")
    func sessionStatsAccuracy() {
        var s = SessionStats()
        s.reviewed = 10
        s.correct  = 8
        #expect(s.accuracy == 0.8)
    }

    @Test("NoteRecord fieldList splitting")
    func noteFieldList() {
        let note = NoteRecord(
            id: 1, guid: "g", notetypeId: 1, modifiedAt: 0,
            fields: "Front\u{1f}Back", sortField: "Front", checksum: 0
        )
        #expect(note.fieldList == ["Front", "Back"])
    }
}
