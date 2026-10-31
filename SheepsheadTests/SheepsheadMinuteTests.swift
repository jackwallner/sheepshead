import XCTest
@testable import Sheepshead

final class SheepsheadMinuteContentTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    func testChallengeIsStableAndSharedForACalendarDay() {
        let day = date(2026, 8, 9)
        let first = SheepsheadMinuteContent.challenge(for: day, calendar: calendar)
        let second = SheepsheadMinuteContent.challenge(for: day, calendar: calendar)

        XCTAssertEqual(first.dayKey, "2026-08-09")
        XCTAssertEqual(first.items.map(\.id), second.items.map(\.id))
        XCTAssertEqual(first.items.map(\.choices), second.items.map(\.choices))
        XCTAssertEqual(first.items.map(\.tiles), second.items.map(\.tiles))
    }

    func testChallengeHasThePromisedFiveQuestionMix() {
        let challenge = SheepsheadMinuteContent.challenge(for: date(2026, 8, 9), calendar: calendar)
        let categories = Dictionary(grouping: challenge.questions, by: \.category).mapValues(\.count)

        XCTAssertEqual(challenge.questions.count, 5)
        XCTAssertEqual(categories[.handReading], 2)
        XCTAssertEqual(categories[.burying], 1)
        XCTAssertEqual(categories[.trickPlay], 2)
    }

    /// The day seed is fixed, so a day that fails to deal fails identically for
    /// every member on that date. `challenge` indexes into the dealt hands, so
    /// a short batch would crash everyone at once. Sweep five years of real day
    /// keys rather than trusting one sampled day.
    func testEveryDaySeedDealsTheFullQuestionSet() {
        var day = date(2026, 1, 1)
        var checked = 0
        while day < date(2031, 1, 1) {
            let key = SheepsheadMinuteContent.key(for: day, calendar: calendar)
            let hands = HandGenerator.batch(count: 2, seed: "sheepshead-minute-\(key)-hands")
            XCTAssertEqual(hands.count, 2, "\(key) dealt \(hands.count) hands")
            checked += 1
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        XCTAssertGreaterThan(checked, 1800)
    }

    func testEveryDailyQuestionIsLegalAndGradeable() {
        let challenge = SheepsheadMinuteContent.challenge(for: date(2026, 8, 9), calendar: calendar)

        for question in challenge.questions {
            let item = question.item
            XCTAssertGreaterThanOrEqual(item.choices.count, 2)
            XCTAssertTrue(item.choices.indices.contains(item.answerIndex), "\(item.id) answer out of range")
            XCTAssertFalse(item.explanation.isEmpty, "\(item.id) has no coaching line")
            XCTAssertFalse(item.explanation.contains("\u{2014}"), "\(item.id) contains an em dash")
        }
    }

    /// Generated daily prompts are one-offs with a unique id per question. If
    /// they entered the review queue it would grow without bound with items
    /// that can never be shown again.
    func testGeneratedDailyItemsAreNotReviewable() {
        let challenge = SheepsheadMinuteContent.challenge(for: date(2026, 8, 9), calendar: calendar)
        let generated = challenge.questions.filter { $0.category == .handReading }

        XCTAssertFalse(generated.isEmpty)
        for question in generated {
            XCTAssertFalse(question.item.isReviewable)
            XCTAssertEqual(question.item.trackingID, PracticeSkill.handReading.rawValue)
        }
    }

    @MainActor
    func testResultScoringAndShareTextMatchTheAnswers() {
        let store = SheepsheadMinuteStore(defaults: UserDefaults(suiteName: "sheepshead.minute.tests")!)
        store.resetAll()
        let challenge = SheepsheadMinuteContent.challenge(for: date(2026, 8, 9), calendar: calendar)
        let answers = [true, false, true, true, false]

        let result = store.record(challenge: challenge, answers: answers)

        XCTAssertEqual(result.score, 3)
        XCTAssertEqual(result.total, 5)
        XCTAssertTrue(result.shareText.contains("3/5"))
        // Recording the same day twice must not double count it.
        XCTAssertEqual(store.record(challenge: challenge, answers: [true, true, true, true, true]).score, 3)
        store.resetAll()
    }
    func testDefaultDayKeyIsGregorianWhateverTheSystemCalendar() {
        let key = SheepsheadMinuteContent.key(for: date(2026, 8, 9))
        XCTAssertEqual(key.prefix(4), "2026")
        XCTAssertEqual(Calendar.gregorianLocal.identifier, .gregorian)
    }

    /// Choices are text, but a bury choice is two cards, so "7 of Hearts, K of
    /// Spades" and "K of Spades, 7 of Hearts" are the same answer. `plus-bury-3`
    /// is authored against its deal order, which put the right pair on screen
    /// twice with one copy graded wrong. Compare the cards, not the strings.
    func testBuryChoicesOfferTheRecommendedPairExactlyOnce() {
        let scenarios = DrillLibrary.rooms.flatMap { room in
            room.drills.flatMap { drill -> [DiscardScenario] in
                if case .discard(let values) = drill.kind { return values }
                return []
            }
        }
        func cards(_ label: String) -> Set<String> { Set(label.components(separatedBy: ", ")) }

        var day = date(2026, 1, 1)
        var checked = 0
        while day < date(2031, 1, 1) {
            let challenge = SheepsheadMinuteContent.challenge(for: day, calendar: calendar)
            guard let item = challenge.questions.first(where: { $0.category == .burying })?.item,
                  let scenario = scenarios.first(where: { $0.deal == item.tiles }) else {
                XCTFail("\(challenge.dayKey) has no bury question built from an authored scenario")
                day = calendar.date(byAdding: .day, value: 1, to: day)!
                continue
            }
            let answer = Set(scenario.recommendedDiscard.map(\.spokenName))
            let copiesOfTheAnswer = item.choices.filter { cards($0) == answer }
            XCTAssertEqual(
                copiesOfTheAnswer.count, 1,
                "\(challenge.dayKey) (\(scenario.id)) lists the recommended pair \(copiesOfTheAnswer.count) times: \(item.choices)"
            )
            XCTAssertEqual(
                Set(item.choices.map(cards)).count, item.choices.count,
                "\(challenge.dayKey) (\(scenario.id)) offers the same two cards twice: \(item.choices)"
            )
            XCTAssertTrue(
                cards(item.choices[item.answerIndex]) == answer,
                "\(challenge.dayKey) (\(scenario.id)) grades a pair other than the recommended bury"
            )
            checked += 1
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        XCTAssertGreaterThan(checked, 1800)
    }

    /// The bury question lists pairs from the deal. A pair that reads the same
    /// as the answer (cards in a different order) would show the right answer
    /// twice, so no choice may repeat across a few years of day keys. Authored
    /// trick questions may be two-way; generated and bury ones offer four.
    func testDailyChoicesAreDistinctAndGeneratedOnesHaveFour() {
        var day = date(2026, 1, 1)
        while day < date(2029, 1, 1) {
            let challenge = SheepsheadMinuteContent.challenge(for: day, calendar: calendar)
            for question in challenge.questions {
                let item = question.item
                if question.category != .trickPlay {
                    XCTAssertGreaterThanOrEqual(item.choices.count, 4, "\(item.id) has too few choices")
                }
                XCTAssertEqual(Set(item.choices).count, item.choices.count, "\(item.id) repeats a choice")
            }
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
    }
}
