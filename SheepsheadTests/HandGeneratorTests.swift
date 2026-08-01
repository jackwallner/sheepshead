import XCTest
@testable import Sheepshead

final class HandGeneratorTests: XCTestCase {
    func testReadsATrumpStack() {
        let cards: [PlayingCard] = [.c(12), .s(11), .d(14), .d(9), .h(12)]
        XCTAssertEqual(HandGenerator.category(for: cards), .trumpStack)
    }

    func testReadsAFailSuit() {
        let cards: [PlayingCard] = [.c(14), .c(10), .c(13), .c(9), .c(7)]
        XCTAssertEqual(HandGenerator.category(for: cards), .failSuit)
        XCTAssertFalse(HandGenerator.fits(cards, .trumpStack))
    }

    func testReadsPointCards() {
        let cards: [PlayingCard] = [.c(14), .d(10), .h(13), .s(14), .c(10)]
        XCTAssertEqual(HandGenerator.category(for: cards), .pointCards)
    }

    func testReadsLowCards() {
        let cards: [PlayingCard] = [.c(7), .h(8), .s(9), .c(8), .h(7)]
        XCTAssertEqual(HandGenerator.category(for: cards), .lowCards)
    }

    func testGeneratedHandsAreLegalAndUnambiguous() {
        for target in HandGenerator.generatableCategories {
            for _ in 0..<20 {
                guard let hand = HandGenerator.hand(for: target) else {
                    XCTFail("Could not deal a hand for \(target.displayName)")
                    continue
                }
                XCTAssertEqual(hand.tiles.count, 5)
                XCTAssertEqual(Set(hand.tiles).count, hand.tiles.count)
                XCTAssertTrue(hand.tiles.allSatisfy(PlayingCard.sheepsheadDeck.contains))
                XCTAssertEqual(HandGenerator.category(for: hand.tiles), target)
                XCTAssertTrue(hand.choices.contains(target))
                XCTAssertGreaterThanOrEqual(hand.choices.count, 3)
                XCTAssertEqual(Set(hand.choices).count, hand.choices.count)
                for choice in hand.choices where choice != target {
                    XCTAssertFalse(HandGenerator.fits(hand.tiles, choice), "\(choice.displayName) is also a correct answer")
                }
                XCTAssertFalse(hand.explanation.isEmpty)
                XCTAssertFalse(hand.explanation.contains("\u{2014}"))
            }
        }
    }

    func testBatchCoversEverySkill() {
        let hands = HandGenerator.batch(count: 60)
        XCTAssertGreaterThan(hands.count, 40)
        XCTAssertEqual(Set(hands.map(\.answer)).count, HandGenerator.generatableCategories.count)
    }

    func testEndlessItemsAreWellFormed() {
        for skill in PracticeSkill.allCases {
            let items = EndlessPractice.items(for: skill, count: 12)
            XCTAssertEqual(items.count, 12)
            for item in items {
                XCTAssertTrue(item.id.hasPrefix(skill.itemPrefix))
                XCTAssertEqual(PracticeSkill.skill(forItemID: item.id), skill)
                XCTAssertGreaterThanOrEqual(item.choices.count, 3)
                XCTAssertTrue(item.choices.indices.contains(item.answerIndex))
                XCTAssertEqual(Set(item.choices).count, item.choices.count)
                XCTAssertFalse(item.explanation.isEmpty)
                XCTAssertNotNil(DrillLibrary.room(id: item.roomID))
            }
        }
    }

    func testTrumpItemsUseLegalCards() {
        let items = EndlessPractice.items(for: .trickPlay, count: 40)
        for item in items {
            guard let card = item.tiles.first else {
                XCTFail("Generated trump item must show a card")
                continue
            }
            XCTAssertTrue(PlayingCard.sheepsheadDeck.contains(card))
            XCTAssertTrue(item.prompt.contains("classify"))
        }
    }

    func testMixedItemsDrawFromEverySkill() {
        let items = EndlessPractice.mixedItems(count: 40)
        XCTAssertEqual(items.count, 40)
        XCTAssertEqual(Set(items.compactMap { PracticeSkill.skill(forItemID: $0.id) }).count,
                       PracticeSkill.allCases.count)
    }
}
