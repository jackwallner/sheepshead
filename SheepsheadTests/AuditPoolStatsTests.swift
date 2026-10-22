import XCTest
@testable import Sheepshead

/// Audit helper: writes what an experienced, repeat player would meet to a
/// text attachment (pool sizes, answer-position bias, repeat rates). It asserts
/// only that the numbers exist, so it documents rather than gates.
@MainActor
final class AuditPoolStatsTests: XCTestCase {
    private func attach(_ name: String, _ lines: [String]) {
        let note = XCTAttachment(string: lines.joined(separator: "\n"))
        note.name = name
        note.lifetime = .keepAlways
        add(note)
    }

    func testPoolAndPositionStats() {
        var out: [String] = []

        for includePro in [false, true] {
            let pool = SessionBuilder.quickSession(count: 100_000, seen: [], missed: [], includePro: includePro)
            let byRoom = Dictionary(grouping: pool, by: \.roomID).mapValues(\.count)
            out.append("quick pool includePro=\(includePro): \(pool.count) items, by room \(byRoom.sorted { $0.key < $1.key })")
            let positions = Dictionary(grouping: pool, by: \.answerIndex).mapValues(\.count)
            out.append("  answer position histogram (authored, after seeded shuffle): \(positions.sorted { $0.key < $1.key })")
            let choiceCounts = Dictionary(grouping: pool, by: { $0.choices.count }).mapValues(\.count)
            out.append("  choices per item: \(choiceCounts.sorted { $0.key < $1.key })")
        }

        // Same session twice with nothing seen: is the order stable between runs?
        let first = SessionBuilder.quickSession(seen: [], missed: [], includePro: false).map(\.id)
        let second = SessionBuilder.quickSession(seen: [], missed: [], includePro: false).map(\.id)
        out.append("two fresh free sessions share \(Set(first).intersection(second).count) of 10 items")

        // A player who has seen every free item: do repeats come back as the same ten?
        let freeAll = SessionBuilder.quickSession(count: 100_000, seen: [], missed: [], includePro: false)
        let seenAll = Set(freeAll.map(\.id))
        let s1 = SessionBuilder.quickSession(seen: seenAll, missed: [], includePro: false).map(\.id)
        let s2 = SessionBuilder.quickSession(seen: seenAll, missed: [], includePro: false).map(\.id)
        out.append("all free items seen: consecutive sessions share \(Set(s1).intersection(s2).count) of 10")

        // Per-drill sizes a free and a member player can open.
        for room in DrillLibrary.rooms {
            for drill in room.drills {
                out.append("room \(room.id) drill \(drill.id) plus=\(drill.isPlus) \(drill.kind.itemCount) \(drill.kind.unitName)")
            }
        }

        // Generated practice: answer position and obviously-wrong distractors.
        for skill in PracticeSkill.allCases {
            let items = EndlessPractice.items(for: skill, count: 400)
            let hist = Dictionary(grouping: items, by: \.answerIndex).mapValues(\.count)
            let choiceCounts = Dictionary(grouping: items, by: { $0.choices.count }).mapValues(\.count)
            out.append("endless \(skill.title): n=\(items.count) answer position \(hist.sorted { $0.key < $1.key }) choices \(choiceCounts.sorted { $0.key < $1.key })")
            let dupPrompts = items.count - Set(items.map { $0.tiles.map(\.shortLabel).joined() }).count
            out.append("  duplicate card sets within 400 draws: \(dupPrompts)")
        }

        let trump = EndlessPractice.items(for: .trickPlay, count: 400)
        let notInDeck = trump.filter { $0.choices[$0.answerIndex] == "Not in the deck" }.count
        out.append("Read the Trump: 'Not in the deck' is the right answer \(notInDeck) of 400 times; always listed last: \(trump.allSatisfy { $0.choices.last == "Not in the deck" })")

        // Trick winner mix, by shape the prompt cannot tell the player.
        var generator = SystemRandomNumberGenerator()
        var winnerIndexHist: [Int: Int] = [:]
        var trumpLedCount = 0
        for _ in 0..<400 {
            for shape in TrickGenerator.Shape.allCases {
                if let trick = TrickGenerator.deal(shape, using: &generator) {
                    winnerIndexHist[trick.winnerIndex, default: 0] += 1
                    if trick.cards[0].isTrump { trumpLedCount += 1 }
                }
            }
        }
        out.append("trick winner seat histogram (0 = led card): \(winnerIndexHist.sorted { $0.key < $1.key }), trump led \(trumpLedCount) of \(400 * 3)")

        // The Hand reading distractor spread an expert sees.
        let hands = HandGenerator.batch(count: 200)
        let handAnswers = Dictionary(grouping: hands, by: \.answer).mapValues(\.count)
        out.append("Read the Holding answers \(handAnswers.map { "\($0.key.displayName)=\($0.value)" }.sorted())")

        // Everything a free player can see, for a difficulty read.
        let prompts = SessionBuilder.quickSession(count: 100_000, seen: [], missed: [], includePro: false)
            .sorted { $0.roomID + $0.id < $1.roomID + $1.id }
            .map { "[\($0.roomID)] \($0.id): \($0.prompt.replacingOccurrences(of: "\n", with: " | ")) -> \($0.choices[$0.answerIndex]) (of \($0.choices.joined(separator: " / ")))" }
        attach("free_pool_prompts", prompts)

        XCTAssertFalse(out.isEmpty)
        attach("pool_stats", out)
    }

    func testReviewQueueAndMasterySemantics() {
        let defaults = UserDefaults(suiteName: "audit-pool-stats")!
        defaults.removePersistentDomain(forName: "audit-pool-stats")
        let store = PracticeRecordStore(defaults: defaults)
        var out: [String] = []
        let now = Date()

        // Miss once, then right once: still in the queue?
        store.record(itemID: "audit-a", roomID: "card-room", correct: false, now: now)
        out.append("after miss: due=\(store.dueCount) queue=\(store.reviewQueue())")
        store.record(itemID: "audit-a", roomID: "card-room", correct: true, now: now)
        let rec1 = store.records["audit-a"]!
        out.append("after miss then hit: streak=\(rec1.streak) interval=\(rec1.intervalDays) due=\(store.dueCount) needsReview=\(rec1.needsReview)")
        store.record(itemID: "audit-a", roomID: "card-room", correct: true, now: now)
        let rec2 = store.records["audit-a"]!
        out.append("after miss, hit, hit: streak=\(rec2.streak) interval=\(rec2.intervalDays) needsReview=\(rec2.needsReview) known=\(rec2.isKnown())")

        // Twenty wrong answers in a skill, then twenty right: does the coach card clear?
        for _ in 0..<20 { store.record(itemID: PracticeSkill.trickWinner.itemPrefix + UUID().uuidString, roomID: "trick-room", correct: false) }
        for n in 1...20 {
            store.record(itemID: PracticeSkill.trickWinner.itemPrefix + UUID().uuidString, roomID: "trick-room", correct: true)
            if n % 5 == 0 {
                let acc = store.skillStats().first?.accuracy ?? 0
                out.append("trickWinner after 20 misses then \(n) hits: lifetime accuracy \(Int(acc * 100))% coach=\(store.skillToCoach() != nil)")
            }
        }
        // 60 more right answers in a row.
        for _ in 0..<60 { store.record(itemID: PracticeSkill.trickWinner.itemPrefix + UUID().uuidString, roomID: "trick-room", correct: true) }
        let acc = store.skillStats().first?.accuracy ?? 0
        out.append("after 60 further straight hits: lifetime accuracy \(Int(acc * 100))% coach=\(store.skillToCoach() != nil)")

        // Review queue is capped at 12 while the badge counts every due item.
        for n in 0..<30 { store.record(itemID: "audit-miss-\(n)", roomID: "card-room", correct: false, now: now) }
        out.append("30 misses: badge dueCount=\(store.dueCount), queue length=\(store.reviewQueue().count)")

        XCTAssertFalse(out.isEmpty)
        attach("review_semantics", out)
        defaults.removePersistentDomain(forName: "audit-pool-stats")
    }
}
