import XCTest
@testable import Sheepshead

final class ContentValidityTests: XCTestCase {
    private var allDrills: [Drill] { DrillLibrary.rooms.flatMap(\.drills) }

    private var allHandMatch: [HandMatchQuestion] {
        allDrills.flatMap { drill in
            if case .handMatch(let questions) = drill.kind { return questions }
            return []
        }
    }

    private var allQuiz: [QuizQuestion] {
        allDrills.flatMap { drill in
            if case .quiz(let questions) = drill.kind { return questions }
            return []
        }
    }

    private var allDiscard: [DiscardScenario] {
        allDrills.flatMap { drill in
            if case .discard(let scenarios) = drill.kind { return scenarios }
            return []
        }
    }

    private var allFlashcards: [Flashcard] {
        allDrills.flatMap { drill in
            if case .flashcards(let cards) = drill.kind { return cards }
            return []
        }
    }

    func testHandMatchQuestionsShowFiveCards() {
        for question in allHandMatch {
            XCTAssertEqual(question.tiles.count, 5, "\(question.id) must show a five-card hand")
            XCTAssertEqual(Set(question.tiles).count, question.tiles.count, "\(question.id) repeats a physical card")
        }
    }

    func testHandMatchAnswerIsAmongChoices() {
        for question in allHandMatch {
            XCTAssertTrue(question.choices.contains(question.answer), "\(question.id) answer missing from choices")
            XCTAssertEqual(Set(question.choices).count, question.choices.count, "\(question.id) has duplicate choices")
        }
    }

    func testBuryHoldingsHaveEightCardsAndRecommendTwo() {
        for scenario in allDiscard {
            XCTAssertEqual(scenario.deal.count, 8, "\(scenario.id) holding must show six dealt cards plus two blind cards")
            XCTAssertEqual(scenario.recommendedDiscard.count, 2, "\(scenario.id) must recommend exactly two cards")
            XCTAssertEqual(Set(scenario.deal).count, scenario.deal.count, "\(scenario.id) repeats a physical card")
            XCTAssertTrue(scenario.recommendedDiscard.allSatisfy(scenario.deal.contains), "\(scenario.id) recommends a card outside the deal")
        }
    }

    /// `trumpStack`, `failSuit`, `pointCards`, and `lowCards` are decidable from
    /// the cards alone, so no holding may offer one of them as a distractor while
    /// actually satisfying it.
    func testHandMatchDistractorsDoNotAlsoFitTheHolding() {
        for question in allHandMatch {
            for choice in question.choices where choice != question.answer {
                XCTAssertFalse(
                    HandGenerator.fits(question.tiles, choice),
                    "\(question.id) marks \(question.answer.displayName) but the holding also fits \(choice.displayName)"
                )
            }
            if HandGenerator.generatableCategories.contains(question.answer) {
                XCTAssertTrue(
                    HandGenerator.fits(question.tiles, question.answer),
                    "\(question.id) is marked \(question.answer.displayName) but the holding does not fit it"
                )
            }
        }
    }

    // MARK: - Bury rules

    private static let failSuits: [Suit] = [.clubs, .hearts, .spades]

    /// Ranks a candidate bury the way the Bury Room teaches it: empty a fail
    /// suit if you can, then bank as many points as possible.
    private func buryScore(deal: [PlayingCard], bury: [PlayingCard]) -> (emptied: Int, banked: Int) {
        let keptFail = deal.filter { $0.isFail && !bury.contains($0) }
        let emptied = Self.failSuits.filter { suit in
            bury.contains { $0.isFail && $0.suit == suit } && !keptFail.contains { $0.suit == suit }
        }.count
        return (emptied, bury.reduce(0) { $0 + $1.pointValue })
    }

    /// The fail suits whose ace this picker could legally name after the bury:
    /// an ace that was never dealt to them, in a suit they still hold.
    private func callableSuits(deal: [PlayingCard], bury: [PlayingCard]) -> Set<Suit> {
        let dealtAceSuits = Set(deal.filter(\.isFailAce).compactMap(\.suit))
        let kept = deal.filter { !bury.contains($0) }
        return Set(kept.filter { $0.isFail }.compactMap(\.suit)).subtracting(dealtAceSuits)
    }

    private func candidateBuries(for scenario: DiscardScenario) -> [[PlayingCard]] {
        let fails = scenario.deal.filter(\.isFail)
        var pairs: [[PlayingCard]] = []
        for first in fails.indices {
            for second in fails.indices where second > first {
                let pair = [fails[first], fails[second]]
                if let called = scenario.calledSuit {
                    let kept = scenario.deal.filter { !pair.contains($0) }
                    guard kept.contains(where: { $0.isFail && $0.suit == called }) else { continue }
                }
                pairs.append(pair)
            }
        }
        return pairs
    }

    func testBuryRecommendationsNeverContainTrump() {
        for scenario in allDiscard {
            XCTAssertTrue(
                scenario.recommendedDiscard.allSatisfy(\.isFail),
                "\(scenario.id) buries trump; queens, jacks, and diamonds are control and stay in the hand"
            )
        }
    }

    func testBuryRecommendationIsTheUniqueBestBury() {
        for scenario in allDiscard {
            let candidates = candidateBuries(for: scenario)
            XCTAssertFalse(candidates.isEmpty, "\(scenario.id) has no legal bury")
            let scores = candidates.map { buryScore(deal: scenario.deal, bury: $0) }
            guard let best = scores.max(by: { ($0.emptied, $0.banked) < ($1.emptied, $1.banked) }) else { continue }
            let winners = zip(candidates, scores).filter { $0.1 == best }.map(\.0)
            XCTAssertEqual(
                winners.count, 1,
                "\(scenario.id) has \(winners.count) equally good buries, so the graded answer is ambiguous"
            )
            XCTAssertEqual(
                Set(scenario.recommendedDiscard), Set(winners.first ?? []),
                "\(scenario.id) recommends \(scenario.recommendedDiscard.map(\.shortLabel)) but \(( winners.first ?? []).map(\.shortLabel)) empties more suits or banks more points"
            )
        }
    }

    func testCalledSuitScenariosObeyTheCallAnAceRules() {
        for scenario in allDiscard {
            guard let called = scenario.calledSuit else { continue }
            XCTAssertNotEqual(called, .diamonds, "\(scenario.id) calls diamonds, which is trump, not a fail suit")
            XCTAssertFalse(
                scenario.deal.contains(.standard(rank: 14, suit: called)),
                "\(scenario.id) names an ace the picker was dealt"
            )
            let kept = scenario.deal.filter { !scenario.recommendedDiscard.contains($0) }
            XCTAssertTrue(
                kept.contains { $0.isFail && $0.suit == called },
                "\(scenario.id) buries its only hold card in the called suit"
            )
            XCTAssertTrue(
                callableSuits(deal: scenario.deal, bury: scenario.recommendedDiscard).contains(called),
                "\(scenario.id) leaves the called suit unplayable"
            )
        }
    }

    func testBuryScenariosAreEitherPartnershipHandsOrMarkedAlone() {
        for scenario in allDiscard {
            let callable = callableSuits(deal: scenario.deal, bury: scenario.recommendedDiscard)
            if scenario.isAlone {
                XCTAssertTrue(
                    callable.isEmpty,
                    "\(scenario.id) is marked alone but could still call \(callable.map(\.displayName))"
                )
            } else {
                XCTAssertFalse(
                    callable.isEmpty,
                    "\(scenario.id) leaves no ace to call, so it must be marked as an alone hand"
                )
            }
        }
    }

    func testGeneratedFailSuitExplanationNamesTheSuit() {
        for suit in Self.failSuits {
            let cards: [PlayingCard] = [14, 10, 13, 9, 8].map { .standard(rank: $0, suit: suit) }
            let text = HandGenerator.explain(cards, answer: .failSuit)
            XCTAssertTrue(
                text.localizedCaseInsensitiveContains(suit.displayName),
                "The generated fail-suit explanation must name the suit, got: \(text)"
            )
            XCTAssertFalse(text.contains("(suit)"), "Unsubstituted placeholder in: \(text)")
        }
    }

    func testBuryHoldingsUseTheSheepsheadDeck() {
        for scenario in allDiscard {
            for card in scenario.deal {
                if case .standard(let rank, _) = card {
                    XCTAssertTrue((7...14).contains(rank), "\(scenario.id) has an invalid Sheepshead rank")
                } else {
                    XCTFail("\(scenario.id) contains a joker; Sheepshead uses a 32-card deck")
                }
            }
        }
    }

    func testAllShownCardsUseTheSheepsheadDeck() {
        let deck = Set(PlayingCard.sheepsheadDeck)
        for room in DrillLibrary.rooms {
            for drill in room.drills {
                switch drill.kind {
                case .flashcards(let cards):
                    for card in cards.flatMap(\.frontTiles) {
                        XCTAssertTrue(deck.contains(card), "\(drill.id) shows a card outside the Sheepshead deck")
                    }
                case .quiz(let questions):
                    for card in questions.flatMap(\.tiles) {
                        XCTAssertTrue(deck.contains(card), "\(drill.id) shows a card outside the Sheepshead deck")
                    }
                case .handMatch(let questions):
                    for question in questions {
                        XCTAssertTrue(question.tiles.allSatisfy(deck.contains), "\(question.id) shows a card outside the Sheepshead deck")
                    }
                case .discard(let scenarios):
                    for scenario in scenarios {
                        XCTAssertTrue(scenario.deal.allSatisfy(deck.contains), "\(scenario.id) shows a card outside the Sheepshead deck")
                    }
                }
            }
        }
        XCTAssertTrue(HowToPlayContent.pages.flatMap(\.tiles).allSatisfy(deck.contains))
    }

    func testQuizAnswerIndicesAreValid() {
        for question in allQuiz {
            XCTAssertTrue(question.choices.indices.contains(question.answerIndex), "\(question.id) has out-of-range answer")
            XCTAssertGreaterThanOrEqual(question.choices.count, 2, "\(question.id) needs at least 2 choices")
            XCTAssertEqual(Set(question.choices).count, question.choices.count, "\(question.id) has duplicate choices")
        }
    }

    func testCardChoicesAreTwoOptionsWithValidAnswer() {
        for card in allFlashcards {
            guard let choice = card.choice else { continue }
            XCTAssertEqual(choice.options.count, 2, "\(card.id) choice must have exactly 2 options")
            XCTAssertTrue(choice.options.indices.contains(choice.answerIndex), "\(card.id) has out-of-range choice answer")
            XCTAssertEqual(Set(choice.options).count, 2, "\(card.id) has duplicate choice options")
        }
    }

    func testAllContentIDsAreUnique() {
        var ids: [String] = []
        for room in DrillLibrary.rooms {
            ids.append(room.id)
            for drill in room.drills {
                ids.append(drill.id)
                switch drill.kind {
                case .flashcards(let cards): ids += cards.map(\.id)
                case .quiz(let questions): ids += questions.map(\.id)
                case .handMatch(let questions): ids += questions.map(\.id)
                case .discard(let scenarios): ids += scenarios.map(\.id)
                }
            }
        }
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate content IDs found")
    }

    func testEveryRoomHasDrillsAndFreeBeginnerModelIsIntact() {
        XCTAssertFalse(DrillLibrary.rooms.isEmpty)
        for room in DrillLibrary.rooms {
            XCTAssertFalse(room.drills.isEmpty, "\(room.id) has no drills")
            for drill in room.drills {
                XCTAssertGreaterThan(drill.kind.itemCount, 0, "\(drill.id) is empty")
            }
        }
        XCTAssertTrue(DrillLibrary.rooms.first?.isFree == true)
        for room in DrillLibrary.rooms {
            if room.id == "pro-tables" {
                XCTAssertFalse(room.isFree)
            } else {
                XCTAssertTrue(room.isFree)
                XCTAssertEqual(room.drills.filter(\.isPlus).count, 1, "\(room.id) should have one Sheepshead+ extra set")
            }
        }
    }

    func testLockedDrillsResolveByMembership() {
        for room in DrillLibrary.rooms {
            for drill in room.drills {
                XCTAssertFalse(room.isLocked(drill, isMember: true))
                XCTAssertEqual(room.isLocked(drill, isMember: false), !room.isFree || drill.isPlus)
            }
        }
    }

    func testNoEmDashesOrStaleCardCopyInPlayerFacingContent() {
        var copy: [String] = []
        for room in DrillLibrary.rooms {
            copy += [room.name, room.tagline]
            for drill in room.drills {
                copy += [drill.title, drill.subtitle]
                switch drill.kind {
                case .flashcards(let cards):
                    copy += cards.flatMap { [$0.frontTitle, $0.frontSubtitle ?? "", $0.backTitle, $0.backBody] + ($0.choice?.options ?? []) }
                case .quiz(let questions):
                    copy += questions.flatMap { [$0.prompt, $0.explanation] + $0.choices }
                case .handMatch(let questions):
                    copy += questions.map(\.explanation)
                case .discard(let scenarios):
                    copy += scenarios.flatMap { [$0.situation, $0.reasoning, $0.tip] }
                }
            }
        }
        copy += HowToPlayContent.pages.flatMap { [$0.title, $0.body, $0.tip ?? ""] }
        for text in copy {
            XCTAssertFalse(text.contains("\u{2014}"), "Em dash found in copy: \(text)")
            XCTAssertFalse(text.localizedCaseInsensitiveContains("tile"), "Stale tile copy found: \(text)")
            XCTAssertFalse(text.localizedCaseInsensitiveContains(["crib", "bage"].joined()), "Stale source copy found: \(text)")
            XCTAssertFalse(text.localizedCaseInsensitiveContains("fifteen"), "Stale fifteen copy found: \(text)")
            XCTAssertFalse(text.localizedCaseInsensitiveContains("pegging"), "Stale pegging copy found: \(text)")
        }
    }

    func testHowToPlayPagesHaveUniqueIDsAndValidCards() {
        let pages = HowToPlayContent.pages
        XCTAssertFalse(pages.isEmpty)
        XCTAssertEqual(Set(pages.map(\.id)).count, pages.count)
        for page in pages {
            XCTAssertEqual(Set(page.tiles).count, page.tiles.count, "\(page.id) repeats a physical card")
            XCTAssertTrue(page.tiles.allSatisfy(PlayingCard.sheepsheadDeck.contains), "\(page.id) shows a card outside the deck")
        }
    }

    func testQuickSessionPullsTenItemsAndPrioritizesMisses() {
        let mix = SessionBuilder.quickSession(seen: [], missed: [], includePro: false)
        XCTAssertEqual(mix.count, 10)
        XCTAssertEqual(Set(mix.map(\.id)).count, 10)
        let missedID = mix[0].id
        let biased = SessionBuilder.quickSession(seen: [missedID], missed: [missedID], includePro: false)
        XCTAssertTrue(biased.contains { $0.id == missedID })
    }

    private var lockedItemIDs: Set<String> {
        var ids: Set<String> = []
        for room in DrillLibrary.rooms {
            for drill in room.drills where room.isLocked(drill, isMember: false) {
                switch drill.kind {
                case .flashcards(let cards): ids.formUnion(cards.map(\.id))
                case .quiz(let questions): ids.formUnion(questions.map(\.id))
                case .handMatch(let questions): ids.formUnion(questions.map(\.id))
                case .discard(let scenarios): ids.formUnion(scenarios.map(\.id))
                }
            }
        }
        return ids
    }

    func testQuickSessionExcludesLockedContentForFreeUsers() {
        let mix = SessionBuilder.quickSession(count: 200, seen: [], missed: [], includePro: false)
        XCTAssertFalse(lockedItemIDs.isEmpty)
        for item in mix {
            XCTAssertFalse(lockedItemIDs.contains(item.id), "\(item.id) leaked into a free session")
        }
    }

    func testQuickSessionIncludesLockedContentForMembers() {
        let mix = SessionBuilder.quickSession(count: 500, seen: [], missed: [], includePro: true)
        XCTAssertFalse(Set(mix.map(\.id)).isDisjoint(with: lockedItemIDs))
    }

    func testQuickSessionItemsAreChoiceOnlyWithValidAnswers() {
        let mix = SessionBuilder.quickSession(count: 50, seen: [], missed: [], includePro: true)
        for item in mix {
            XCTAssertGreaterThanOrEqual(item.choices.count, 2)
            XCTAssertTrue(item.choices.indices.contains(item.answerIndex))
        }
    }

    func testQuickSessionExcludesPlainFlashcardsAndDiscard() {
        let plainFlashcardIDs = Set(allFlashcards.filter { $0.choice == nil }.map(\.id))
        let discardIDs = Set(allDiscard.map(\.id))
        let mix = SessionBuilder.quickSession(count: 200, seen: [], missed: [], includePro: true)
        for item in mix {
            XCTAssertFalse(plainFlashcardIDs.contains(item.id))
            XCTAssertFalse(discardIDs.contains(item.id))
        }
    }
}
