import XCTest
@testable import Sheepshead

final class RulesAuditTests: XCTestCase {
    private func card(_ code: String) -> PlayingCard {
        let suits: [Character: Suit] = ["C": .clubs, "D": .diamonds, "H": .hearts, "S": .spades]
        return .standard(rank: Int(code.dropFirst())!, suit: suits[code.first!]!)
    }
    private func reference() throws -> [String: Any] {
        let url = Bundle(for: Self.self).url(forResource: "rules-reference", withExtension: "json")
            ?? URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Resources/rules-reference.json")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }
    func testEveryCardValueAndFullTrumpOrder() throws {
        let deck = PlayingCard.sheepsheadDeck
        XCTAssertEqual(Set(deck).count, 32)
        XCTAssertEqual(deck.filter(\.isTrump).count, 14)
        XCTAssertEqual(deck.filter(\.isFail).count, 18)
        XCTAssertEqual(deck.reduce(0) { $0 + $1.pointValue }, 120)
        for (rank, points) in [(7, 0), (8, 0), (9, 0), (10, 10), (11, 2), (12, 3), (13, 4), (14, 11)] {
            for suit in Suit.allCases { XCTAssertEqual(PlayingCard.standard(rank: rank, suit: suit).pointValue, points) }
        }
        let order = (try reference()["order"] as! [String]).map(card)
        XCTAssertEqual(deck.filter(\.isTrump).sorted { $0.trumpStrength > $1.trumpStrength }, order)
        for suit in [Suit.clubs, .hearts, .spades] {
            let fail = [14, 10, 13, 9, 8, 7].map { PlayingCard.standard(rank: $0, suit: suit) }
            XCTAssertEqual(fail.sorted { $0.failStrength > $1.failStrength }, fail)
        }
    }
    func testFollowingAndCalledAceReservation() throws {
        for r in try reference()["legal"] as! [[String: Any]] {
            let hand = (r["hand"] as! [String]).map(card)
            let led = (r["led"] as? String).map(card)
            let call = (r["calledSuit"] as? String).flatMap(Suit.init(rawValue:))
            XCTAssertEqual(SheepsheadRules.legal(hand, led: led, calledSuit: call,
                isPicker: r["isPicker"] as! Bool, calledSuitOpened: r["opened"] as! Bool, calledRank: r["calledRank"] as? Int ?? 14),
                (r["expected"] as! [String]).map(card), r["id"] as! String)
            if let question = MoreContent.advancedRules.first(where: { $0.id == r["id"] as? String }) {
                XCTAssertEqual(question.tiles, hand)
                XCTAssertEqual(question.answerIndex, 0)
            }
        }
    }
    func testCallingCannotUseAceFromHandBlindOrBury() throws {
        for r in try reference()["calls"] as! [[String: Any]] {
            XCTAssertEqual(SheepsheadRules.callableSuits(dealIncludingBlind: (r["deal"] as! [String]).map(card),
                bury: (r["bury"] as! [String]).map(card)), (r["expected"] as! [String]).map { Suit(rawValue: $0)! })
        }
        for r in try reference()["tenCalls"] as! [[String: Any]] {
            XCTAssertEqual(SheepsheadRules.callableTenSuits(dealIncludingBlind: (r["deal"] as! [String]).map(card),
                bury: (r["bury"] as! [String]).map(card)), (r["expected"] as! [String]).map { Suit(rawValue: $0)! })
        }
    }
    func testTrickWinnersAndSixtySixtyLoss() throws {
        for r in try reference()["tricks"] as! [[String: Any]] {
            XCTAssertEqual(SheepsheadRules.winner((r["cards"] as! [String]).map(card)), r["winner"] as? Int)
            XCTAssertEqual(TrickGenerator.winnerIndex(of: (r["cards"] as! [String]).map(card)), r["winner"] as? Int)
        }
        for (tricks, bury, won) in [(49, [PlayingCard.c(14), .h(7)], false), (50, [.c(14), .h(7)], true),
                                   (60, [.c(7), .h(8)], false), (61, [.c(7), .h(8)], true)] {
            XCTAssertEqual(SheepsheadRules.pickerWins(trickPoints: tricks, bury: bury), won)
        }
    }
    func testBuryLegalityIsSeparateFromTheGradedStrategy() {
        XCTAssertTrue(CardBasicsContent.meetTheCards.first(where: { $0.id == "cards-goal" })!.backBody.contains("plus the two buried cards"))
        let deal: [PlayingCard] = [.c(12), .s(12), .d(7), .d(8), .h(14), .h(7), .s(10), .s(9)]
        for bury in [[PlayingCard.c(12), .d(7)], [.h(14), .h(7)], [.d(7), .d(8)]] {
            XCTAssertTrue(SheepsheadRules.canBury(bury, from: deal))
        }
        for bury in [[PlayingCard.c(12)], [.h(14), .h(14)], [.h(14), .c(7)]] {
            XCTAssertFalse(SheepsheadRules.canBury(bury, from: deal))
        }
        for room in DrillLibrary.rooms {
            for drill in room.drills {
                guard case .discard(let scenarios) = drill.kind else { continue }
                for scenario in scenarios {
                    XCTAssertTrue(scenario.situation.contains("For this drill"))
                    XCTAssertTrue(SheepsheadRules.canBury(scenario.recommendedDiscard, from: scenario.deal))
                    if let called = scenario.calledSuit {
                        XCTAssertTrue(SheepsheadRules.callableSuits(dealIncludingBlind: scenario.deal, bury: scenario.recommendedDiscard).contains(called))
                    }
                }
            }
        }
        XCTAssertTrue(HowToPlayContent.pages[0].body.contains("no under calls or called tens"))
        XCTAssertTrue(HowToPlayContent.pages.first(where: { $0.id == "sheep-tricks" })!.body.contains("including trump"))
        XCTAssertTrue(DiscardContent.strategyCards.first(where: { $0.id == "bury-no-trump" })!.backBody.contains("Burying trump is legal"))
    }
}
