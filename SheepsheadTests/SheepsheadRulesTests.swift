import XCTest
@testable import Sheepshead

/// The trick-winner engine and the point counter, checked against the printed
/// five-player called-ace rules (pagat.com and sheepshead.org): 14 trump from
/// Q-clubs down to 7-diamonds, fail suits ranked A 10 K 9 8 7, and 120 points.
/// The oracle here is a flat list of names, written independently of the
/// strength numbers the engine uses.
final class SheepsheadRulesTests: XCTestCase {
    private let trumpOrder = [
        "Qc", "Qs", "Qh", "Qd", "Jc", "Js", "Jh", "Jd",
        "Ad", "10d", "Kd", "9d", "8d", "7d",
    ]
    private let failOrder = ["A", "10", "K", "9", "8", "7"]

    private func name(_ card: PlayingCard) -> String {
        guard case .standard(let rank, let suit) = card else { return "joker" }
        let letter = ["clubs": "c", "spades": "s", "hearts": "h", "diamonds": "d"][suit.rawValue]!
        return PlayingCard.rankLabel(rank) + letter
    }

    private func oracleWinner(_ cards: [PlayingCard]) -> PlayingCard {
        let names = cards.map(name)
        if let best = trumpOrder.first(where: names.contains) {
            return cards[names.firstIndex(of: best)!]
        }
        let ledSuit = cards[0].suit
        let followers = cards.filter { $0.suit == ledSuit }
        return followers.min {
            failOrder.firstIndex(of: PlayingCard.rankLabel($0.rankValue))!
                < failOrder.firstIndex(of: PlayingCard.rankLabel($1.rankValue))!
        }!
    }

    private func winner(_ cards: [PlayingCard]) -> PlayingCard {
        cards[TrickGenerator.winnerIndex(of: cards)!]
    }

    // MARK: - Trump ladder

    func testTrumpStrengthSortsIntoThePrintedLadder() {
        let trump = PlayingCard.sheepsheadDeck.filter(\.isTrump)
        let sorted = trump.sorted { $0.trumpStrength > $1.trumpStrength }
        XCTAssertEqual(sorted.map(name), trumpOrder)
        XCTAssertEqual(Set(trump.map(\.trumpStrength)).count, 14, "No two trump may tie")
    }

    func testFailStrengthSortsEachFailSuitIntoAceTenKing() {
        for suit in [Suit.clubs, .spades, .hearts] {
            let cards = PlayingCard.sheepsheadDeck.filter { $0.isFail && $0.suit == suit }
            XCTAssertEqual(cards.count, 6)
            let sorted = cards.sorted { $0.failStrength > $1.failStrength }
            XCTAssertEqual(sorted.map { PlayingCard.rankLabel($0.rankValue) }, failOrder, suit.displayName)
        }
    }

    func testQueenBeatsJackBeatsDiamondAce() {
        // The lowest queen beats the highest jack; the lowest jack beats the ace of diamonds.
        XCTAssertEqual(winner([.c(11), .d(12)]), .d(12))
        XCTAssertEqual(winner([.d(12), .c(11)]), .d(12))
        XCTAssertEqual(winner([.d(14), .d(11)]), .d(11))
        XCTAssertEqual(winner([.d(11), .d(14)]), .d(11))
        XCTAssertEqual(winner([.d(14), .d(11), .d(12)]), .d(12))
        // Queen of clubs beats the other three queens in any order.
        XCTAssertEqual(winner([.d(12), .h(12), .s(12), .c(12), .d(14)]), .c(12))
        XCTAssertEqual(winner([.s(12), .c(12), .h(12), .d(12), .c(11)]), .c(12))
        // Jacks keep the clubs, spades, hearts, diamonds order.
        XCTAssertEqual(winner([.d(11), .h(11), .s(11), .d(14), .d(10)]), .s(11))
    }

    func testQueensAndJacksAreTrumpWhateverTheirPrintedSuit() {
        // Clubs led: the jack of clubs is trump, so it cuts the ace of clubs.
        XCTAssertEqual(winner([.c(14), .c(10), .c(11)]), .c(11))
        // A queen of hearts beats the ace of hearts when hearts are led.
        XCTAssertEqual(winner([.h(14), .h(12), .h(10)]), .h(12))
        XCTAssertTrue(PlayingCard.c(11).isTrump && !PlayingCard.c(11).isFail)
        XCTAssertTrue(PlayingCard.h(12).isTrump && !PlayingCard.h(12).isFail)
    }

    // MARK: - Fail suits

    func testFailAceLosesToTheSevenOfDiamonds() {
        XCTAssertEqual(winner([.c(14), .c(10), .c(13), .d(7), .c(9)]), .d(7))
        XCTAssertEqual(winner([.s(14), .d(7)]), .d(7))
        XCTAssertEqual(winner([.d(7), .h(14)]), .d(7))
        // Among several trumps the highest still wins: 9 beats 8 beats 7 of diamonds.
        XCTAssertEqual(winner([.h(14), .d(8), .d(7), .d(9)]), .d(9))
    }

    func testLedFailTenBeatsTheKingButNotTheAce() {
        XCTAssertEqual(winner([.h(13), .h(10), .h(9)]), .h(10))
        XCTAssertEqual(winner([.s(10), .s(13)]), .s(10))
        XCTAssertEqual(winner([.c(10), .c(14), .c(13)]), .c(14))
        // King beats 9, 8 and 7.
        XCTAssertEqual(winner([.c(7), .c(8), .c(9), .c(13)]), .c(13))
        XCTAssertEqual(winner([.c(9), .c(8), .c(7)]), .c(9))
    }

    func testOffSuitDiscardsNeverWin() {
        // Led 7 of clubs: the ace and 10 of other fail suits are discards.
        XCTAssertEqual(winner([.c(7), .s(14), .h(14), .s(10), .h(10)]), .c(7))
        XCTAssertEqual(winner([.h(9), .c(14), .s(14), .h(7), .c(10)]), .h(9))
        // Every non-trump off-suit card loses to the lone led card, however high.
        let fail = PlayingCard.sheepsheadDeck.filter(\.isFail)
        for led in fail {
            for other in fail where other.suit != led.suit {
                XCTAssertEqual(winner([led, other]), led, "\(other.shortLabel) must not beat led \(led.shortLabel)")
            }
        }
    }

    func testTrickWithNoTrumpAndMixedSuits() {
        // Hearts led. The club ace and spade ace are discards.
        XCTAssertEqual(winner([.h(9), .c(13), .s(14), .h(10), .h(8)]), .h(10))
        // The led suit is the only suit that competes, even when the led card is the lowest.
        XCTAssertEqual(winner([.s(7), .h(14), .c(14), .s(8)]), .s(8))
    }

    // MARK: - Exhaustive checks against the oracle

    func testEveryPairOfCardsInEveryOrderMatchesTheOracle() {
        let deck = PlayingCard.sheepsheadDeck
        for first in deck {
            for second in deck where first != second {
                XCTAssertEqual(
                    winner([first, second]), oracleWinner([first, second]),
                    "\(first.shortLabel) then \(second.shortLabel)"
                )
            }
        }
    }

    func testFiveCardTricksMatchTheOracle() {
        var generator = StableSeededGenerator(seed: "sheepshead-rules-tricks")
        let deck = PlayingCard.sheepsheadDeck
        for _ in 0..<5000 {
            let cards = Array(deck.shuffled(using: &generator).prefix(5))
            XCTAssertEqual(winner(cards), oracleWinner(cards), cards.map(\.shortLabel).joined(separator: " "))
        }
    }

    func testAnyTrumpBeatsEveryFailCard() {
        let deck = PlayingCard.sheepsheadDeck
        for trump in deck.filter(\.isTrump) {
            for fail in deck.filter(\.isFail) {
                XCTAssertEqual(winner([fail, trump]), trump)
                XCTAssertEqual(winner([trump, fail]), trump)
            }
        }
    }

    // MARK: - Deck and points

    func testDeckShapeIsFourteenTrumpAndEighteenFail() {
        let deck = PlayingCard.sheepsheadDeck
        XCTAssertEqual(deck.count, 32)
        XCTAssertEqual(Set(deck).count, 32)
        XCTAssertEqual(deck.filter(\.isTrump).count, 14)
        XCTAssertEqual(deck.filter(\.isFail).count, 18)
        XCTAssertEqual(deck.filter { $0.isTrump && $0.suit == .diamonds }.count, 8)
        XCTAssertTrue(deck.filter { $0.rankValue == 11 || $0.rankValue == 12 }.allSatisfy(\.isTrump))
    }

    func testPointValuePerRank() {
        let expected = [14: 11, 10: 10, 13: 4, 12: 3, 11: 2, 9: 0, 8: 0, 7: 0]
        for card in PlayingCard.sheepsheadDeck {
            XCTAssertEqual(card.pointValue, expected[card.rankValue], card.shortLabel)
        }
    }

    func testFullDeckSumsToOneHundredTwenty() {
        let deck = PlayingCard.sheepsheadDeck
        XCTAssertEqual(deck.reduce(0) { $0 + $1.pointValue }, 120)
        // 45 in trump (4 queens 12, 4 jacks 8, diamond ace 11, 10, king 4) and 25 in each fail suit.
        XCTAssertEqual(deck.filter(\.isTrump).reduce(0) { $0 + $1.pointValue }, 45)
        for suit in [Suit.clubs, .spades, .hearts] {
            XCTAssertEqual(deck.filter { $0.isFail && $0.suit == suit }.reduce(0) { $0 + $1.pointValue }, 25)
        }
    }

    func testEveryDealSumsToOneHundredTwenty() {
        var generator = StableSeededGenerator(seed: "sheepshead-rules-deals")
        for _ in 0..<200 {
            let deck = PlayingCard.sheepsheadDeck.shuffled(using: &generator)
            var hands = (0..<5).map { Array(deck[($0 * 6)..<($0 * 6 + 6)]) }
            let blind = Array(deck[30..<32])
            hands.append(blind)
            XCTAssertEqual(hands.flatMap { $0 }.count, 32)
            XCTAssertEqual(hands.flatMap { $0 }.reduce(0) { $0 + $1.pointValue }, 120)
            XCTAssertEqual(Set(hands.flatMap { $0 }).count, 32)
        }
    }

    func testTrickPointsAddTheCapturedCards() {
        // K 4 + 7 0 + 7 0 + A 11 + J 2 = 17, the worked example on the how-to-play page.
        let cards: [PlayingCard] = [.c(13), .c(7), .d(7), .c(14), .h(11)]
        let trick = TrickGenerator.Trick(cards: cards, shape: .trumpIn, winnerIndex: TrickGenerator.winnerIndex(of: cards)!)
        XCTAssertEqual(trick.winner, .h(11))
        XCTAssertEqual(trick.points, 17)
        // A trick of three aces and two tens is the most a five-card trick can hold from the fail suits.
        XCTAssertEqual([PlayingCard.c(14), .s(14), .h(14), .c(10), .s(10)].reduce(0) { $0 + $1.pointValue }, 53)
        // Nine, eight and seven are worth nothing.
        XCTAssertEqual([PlayingCard.c(9), .h(8), .s(7), .c(8), .h(7)].reduce(0) { $0 + $1.pointValue }, 0)
    }

    func testPointChoicesAlwaysHoldTheTrueTotalFirstAndOnce() {
        var generator = StableSeededGenerator(seed: "sheepshead-rules-points")
        for _ in 0..<300 {
            let cards = Array(PlayingCard.sheepsheadDeck.shuffled(using: &generator).prefix(5))
            let total = cards.reduce(0) { $0 + $1.pointValue }
            let choices = TrickGenerator.pointChoices(for: cards)
            XCTAssertEqual(choices.first, total)
            XCTAssertEqual(choices.filter { $0 == total }.count, 1)
            XCTAssertEqual(Set(choices).count, choices.count)
            XCTAssertTrue(choices.allSatisfy { $0 >= 0 })
        }
    }

    // MARK: - Called ace

    func testOnlyClubSpadeAndHeartAcesCanBeCalled() {
        let callable = PlayingCard.sheepsheadDeck.filter(\.isFailAce)
        XCTAssertEqual(Set(callable), [.c(14), .s(14), .h(14)])
        XCTAssertFalse(PlayingCard.d(14).isFailAce, "The ace of diamonds is trump and can never be called")
    }

    // MARK: - Hand reading edge cases

    func testQueenOrJackOfASuitNeverMakesAFailSuitHolding() {
        XCTAssertFalse(HandGenerator.fits([.c(14), .c(10), .c(13), .c(9), .c(11)], .failSuit))
        XCTAssertFalse(HandGenerator.fits([.c(14), .c(10), .c(13), .c(9), .c(12)], .failSuit))
        XCTAssertTrue(HandGenerator.fits([.c(14), .c(10), .c(13), .c(9), .c(8)], .failSuit))
        // Five diamonds are a trump stack, not a fail suit.
        XCTAssertTrue(HandGenerator.fits([.d(14), .d(10), .d(13), .d(9), .d(7)], .trumpStack))
        XCTAssertFalse(HandGenerator.fits([.d(14), .d(10), .d(13), .d(9), .d(7)], .failSuit))
        // A diamond or a jack is never a low fail card.
        XCTAssertFalse(HandGenerator.fits([.c(7), .h(8), .s(9), .c(8), .d(7)], .lowCards))
        XCTAssertFalse(HandGenerator.fits([.c(7), .h(8), .s(9), .c(8), .h(11)], .lowCards))
    }
}
