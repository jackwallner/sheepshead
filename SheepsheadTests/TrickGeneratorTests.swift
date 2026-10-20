import XCTest
@testable import Sheepshead

/// The generated trick answers are checked against an oracle written from the
/// printed rules (an explicit trump ladder), not against `trumpStrength`, so a
/// bug in the strength numbers cannot also hide in the test.
final class TrickGeneratorTests: XCTestCase {
    private let trumpLadder: [PlayingCard] = [
        .c(12), .s(12), .h(12), .d(12),
        .c(11), .s(11), .h(11), .d(11),
        .d(14), .d(10), .d(13), .d(9), .d(8), .d(7),
    ]
    private let failRanks = [14, 10, 13, 9, 8, 7]

    private func oracleWinner(_ cards: [PlayingCard]) -> PlayingCard {
        if let best = trumpLadder.first(where: cards.contains) { return best }
        let led = cards[0].suit
        let followers = cards.filter { $0.suit == led }
        return followers.min { failRanks.firstIndex(of: $0.rankValue)! < failRanks.firstIndex(of: $1.rankValue)! }!
    }

    func testTrumpLadderCoversTheFourteenTrump() {
        XCTAssertEqual(Set(trumpLadder), Set(PlayingCard.sheepsheadDeck.filter(\.isTrump)))
        XCTAssertEqual(trumpLadder.count, 14)
    }

    func testKnownTricks() {
        // Off-suit ace cannot beat the led suit.
        let followSuit: [PlayingCard] = [.c(9), .s(14), .c(13), .h(10), .c(7)]
        XCTAssertEqual(followSuit[TrickGenerator.winnerIndex(of: followSuit)!], .c(13))
        // A low trump beats the led fail ace.
        let cut: [PlayingCard] = [.h(14), .h(10), .d(7), .s(13), .c(9)]
        XCTAssertEqual(cut[TrickGenerator.winnerIndex(of: cut)!], .d(7))
        // Queen of clubs outranks everything, jack of clubs outranks diamonds.
        let order: [PlayingCard] = [.d(14), .c(11), .s(12), .h(11), .c(12)]
        XCTAssertEqual(order[TrickGenerator.winnerIndex(of: order)!], .c(12))
        let jackOverDiamond: [PlayingCard] = [.d(14), .d(10), .d(13), .s(11), .d(9)]
        XCTAssertEqual(jackOverDiamond[TrickGenerator.winnerIndex(of: jackOverDiamond)!], .s(11))
    }

    func testRejectsMalformedTricks() {
        XCTAssertNil(TrickGenerator.winnerIndex(of: [.c(9)]))
        XCTAssertNil(TrickGenerator.winnerIndex(of: [.c(9), .c(9)]))
    }

    func testEveryDealtTrickMatchesTheOracleAndItsShape() {
        for shape in TrickGenerator.Shape.allCases {
            for _ in 0..<60 {
                guard let trick = TrickGenerator.deal(shape) else {
                    XCTFail("Could not deal \(shape)")
                    continue
                }
                XCTAssertEqual(trick.cards.count, 5)
                XCTAssertEqual(Set(trick.cards).count, 5)
                XCTAssertTrue(trick.cards.allSatisfy(PlayingCard.sheepsheadDeck.contains))
                XCTAssertEqual(trick.winner, oracleWinner(trick.cards))
                XCTAssertTrue(TrickGenerator.fits(trick.cards, shape))
            }
        }
    }

    func testFollowSuitTricksNeverContainTrumpAndHideAHigherOffSuitCard() {
        for _ in 0..<60 {
            guard let trick = TrickGenerator.deal(.followSuit) else { return XCTFail("no deal") }
            XCTAssertFalse(trick.cards.contains(where: \.isTrump))
            XCTAssertEqual(trick.winner.suit, trick.cards[0].suit)
            let offSuit = trick.cards.filter { $0.suit != trick.cards[0].suit }
            XCTAssertTrue(offSuit.contains { $0.failStrength > trick.winner.failStrength },
                          "The lesson needs an off-suit card that looks stronger")
        }
    }

    func testTrumpInTricksAreLedFailAndWonByTrump() {
        for _ in 0..<60 {
            guard let trick = TrickGenerator.deal(.trumpIn) else { return XCTFail("no deal") }
            XCTAssertTrue(trick.cards[0].isFail)
            XCTAssertTrue(trick.winner.isTrump)
        }
    }

    func testSeededDealsAreReproducible() {
        var a = StableSeededGenerator(seed: "trick-test")
        var b = StableSeededGenerator(seed: "trick-test")
        let first = EndlessPractice.trickWinnerItems(count: 6, using: &a)
        let second = EndlessPractice.trickWinnerItems(count: 6, using: &b)
        XCTAssertEqual(first.map(\.choices), second.map(\.choices))
        XCTAssertEqual(first.map(\.answerIndex), second.map(\.answerIndex))
    }

    func testTrickWinnerItemsGradeTheRightCard() {
        let items = EndlessPractice.items(for: .trickWinner, count: 40)
        XCTAssertEqual(items.count, 40)
        for item in items {
            XCTAssertEqual(PracticeSkill.skill(forItemID: item.id), .trickWinner)
            XCTAssertEqual(item.tiles.count, 5)
            XCTAssertEqual(Set(item.choices).count, item.choices.count)
            XCTAssertEqual(item.choices.count, 4)
            let expected = oracleWinner(item.tiles).spokenName
            XCTAssertEqual(item.choices[item.answerIndex], expected)
            XCTAssertTrue(item.choices.allSatisfy { name in item.tiles.contains { $0.spokenName == name } })
            XCTAssertFalse(item.explanation.contains("\u{2014}"))
            XCTAssertTrue(item.explanation.contains(expected))
        }
    }

    func testDeckPointsTotalOneHundredTwenty() {
        // 4 suits x (11 + 10 + 4 + 3 + 2) = 120, the table's full score.
        XCTAssertEqual(PlayingCard.sheepsheadDeck.reduce(0) { $0 + $1.pointValue }, 120)
    }

    func testPointCountItemsAreCorrectAndUnambiguous() {
        let table = [14: 11, 10: 10, 13: 4, 12: 3, 11: 2, 9: 0, 8: 0, 7: 0]
        let items = EndlessPractice.items(for: .pointCount, count: 60)
        for item in items {
            let total = item.tiles.reduce(0) { $0 + table[$1.rankValue]! }
            XCTAssertEqual(item.choices[item.answerIndex], "\(total) points")
            XCTAssertEqual(Set(item.choices).count, item.choices.count)
            XCTAssertEqual(item.choices.count, 4)
            XCTAssertEqual(Set(item.tiles).count, 5)
        }
    }

    func testPointChoicesIncludeAZeroPointTrick() {
        let choices = TrickGenerator.pointChoices(for: [.c(7), .h(8), .s(9), .c(8), .h(7)])
        XCTAssertEqual(choices.first, 0)
        XCTAssertGreaterThanOrEqual(Set(choices).count, 3)
    }
}

@MainActor
final class MasteryTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: PracticeRecordStore!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "MasteryTests")!
        defaults.removePersistentDomain(forName: "MasteryTests")
        store = PracticeRecordStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "MasteryTests")
        super.tearDown()
    }

    private var cardRoom: Room { DrillLibrary.room(id: "card-room")! }

    func testUntouchedRoomHasNothingKnown() {
        let mastery = store.mastery(for: cardRoom, isMember: false)
        XCTAssertEqual(mastery.level, .untouched)
        XCTAssertEqual(mastery.known, 0)
        XCTAssertGreaterThan(mastery.total, 0)
    }

    func testOneCorrectAnswerIsLearningNotKnown() {
        let id = PracticeRecordStore.trackableItemIDs(in: cardRoom, isMember: false)[0]
        store.record(itemID: id, roomID: cardRoom.id, correct: true)
        let mastery = store.mastery(for: cardRoom, isMember: false)
        XCTAssertEqual(mastery.known, 0)
        XCTAssertEqual(mastery.level, .learning)
    }

    func testTwoInARowIsKnownAndAMissUndoesIt() {
        let id = PracticeRecordStore.trackableItemIDs(in: cardRoom, isMember: false)[0]
        store.record(itemID: id, roomID: cardRoom.id, correct: true)
        store.record(itemID: id, roomID: cardRoom.id, correct: true)
        XCTAssertEqual(store.mastery(for: cardRoom, isMember: false).known, 1)
        store.record(itemID: id, roomID: cardRoom.id, correct: false)
        XCTAssertEqual(store.mastery(for: cardRoom, isMember: false).known, 0)
    }

    func testKnownItemLapsesAfterAFullIntervalPastDue() {
        let id = PracticeRecordStore.trackableItemIDs(in: cardRoom, isMember: false)[0]
        let start = Date()
        store.record(itemID: id, roomID: cardRoom.id, correct: true, now: start)
        store.record(itemID: id, roomID: cardRoom.id, correct: true, now: start)
        let record = store.records[id]!
        XCTAssertTrue(record.isKnown(now: start))
        XCTAssertTrue(record.isKnown(now: start.addingTimeInterval(4 * 86_400)))
        XCTAssertFalse(record.isKnown(now: start.addingTimeInterval(8 * 86_400)))
    }

    func testFreePlayersAreNotMeasuredAgainstLockedSets() {
        let free = PracticeRecordStore.trackableItemIDs(in: cardRoom, isMember: false)
        let member = PracticeRecordStore.trackableItemIDs(in: cardRoom, isMember: true)
        XCTAssertLessThan(free.count, member.count)
        XCTAssertTrue(Set(free).isSubset(of: Set(member)))
        let locked = PracticeRecordStore.trackableItemIDs(in: DrillLibrary.room(id: "pro-tables")!, isMember: false)
        XCTAssertTrue(locked.isEmpty)
    }

    func testTrackableIDsAreUnique() {
        for room in DrillLibrary.rooms {
            let ids = PracticeRecordStore.trackableItemIDs(in: room, isMember: true)
            XCTAssertEqual(Set(ids).count, ids.count, room.id)
        }
    }

    func testLevelThresholds() {
        XCTAssertEqual(MasteryLevel.level(known: 0, total: 10), .untouched)
        XCTAssertEqual(MasteryLevel.level(known: 0, total: 10, attempted: 3), .learning)
        XCTAssertEqual(MasteryLevel.level(known: 2, total: 10), .learning)
        XCTAssertEqual(MasteryLevel.level(known: 5, total: 10), .solid)
        XCTAssertEqual(MasteryLevel.level(known: 9, total: 10), .sharp)
    }

    func testSkillCoachNeedsEnoughShakyAnswers() {
        let skill = PracticeSkill.trickWinner
        for _ in 0..<3 { store.record(itemID: skill.itemPrefix + UUID().uuidString, roomID: skill.roomID, correct: false) }
        XCTAssertNil(store.skillToCoach(), "Three answers is not enough to coach on")
        for _ in 0..<7 { store.record(itemID: skill.itemPrefix + UUID().uuidString, roomID: skill.roomID, correct: false) }
        XCTAssertEqual(store.skillToCoach()?.skill, skill)
        for _ in 0..<40 { store.record(itemID: skill.itemPrefix + UUID().uuidString, roomID: skill.roomID, correct: true) }
        XCTAssertNil(store.skillToCoach(), "A recovered skill stops being flagged")
    }

    func testWorkOnPicksTheLeastMasteredStartedRoom() {
        let cardIDs = PracticeRecordStore.trackableItemIDs(in: cardRoom, isMember: false)
        let trumpRoom = DrillLibrary.room(id: "trump-room")!
        let trumpIDs = PracticeRecordStore.trackableItemIDs(in: trumpRoom, isMember: false)
        for id in cardIDs.prefix(4) {
            store.record(itemID: id, roomID: cardRoom.id, correct: true)
            store.record(itemID: id, roomID: cardRoom.id, correct: true)
        }
        store.record(itemID: trumpIDs[0], roomID: trumpRoom.id, correct: false)
        XCTAssertEqual(store.roomToWorkOn(isMember: false)?.roomID, "trump-room")
    }

    func testCurrentVersionHasReleaseNotes() {
        XCTAssertNotNil(WhatsNew.releases.first { $0.version == "1.2.4" })
    }
}
