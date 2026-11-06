// State machine audit 2026-11-06, repro suite. Moved out of the test target so it does not break the build.
// Copy to SheepsheadUITests/StateMachineAuditRepro.swift (UI test target) and run:
//   gh-sim test --scheme SheepsheadUITests --only SheepsheadUITests/StateMachineAuditRepro
// Needs the NSPredicate fix at FlashcardDeckUITests.swift:76 or the target does not compile on Xcode 27.1.
import XCTest

/// State machine audit 2026-11-06, UI half. Drives the real Card Room deck and
/// the real Fix My Mistakes runner. Launch arguments blank the stored practice
/// data so every test starts from an empty record, whatever ran before it.
final class StateMachineAuditRepro: XCTestCase {

    private func launch(member: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.sheepshead")
        app.launchArguments += [
            "-progress.hasOnboarded", "YES",
            "-sheepshead.hasReadPrimer", "YES",
            "-sheepshead.skillLevel", "basics",
            "-sheepshead.hasSwipedDeck", "YES",
            "-sheepshead.suppressWhatsNew",
            // A string where the app expects Data/array/dictionary reads as absent.
            "-practice.records", "none",
            "-progress.seenItems", "none",
            "-progress.missedItems", "none",
            "-progress.completions", "none",
            "-progress.totalSessions", "0",
            "-progress.streakCount", "0",
            "-mastery.ledger", "none",
        ]
        if member { app.launchArguments += ["-subscription.localProOverride", "YES"] }
        app.launch()
        return app
    }

    // MARK: - Flashcard Undo

    /// Control: one honest correct answer on card one is not "locked in".
    func testControlOneAnswerLocksInNothing() {
        let app = launch()
        openDeck(app)
        answerFirstCardRight(app)
        XCTAssertEqual(lockedIn(afterLeavingDeck: app), 0, "one correct answer is not two in a row")
    }

    /// Promise: the toolbar arrow is labelled "Undo last answer". Answer card one
    /// right, undo it, answer it right again: the player has given ONE answer.
    /// Mastery.swift: "an item counts only after two correct answers in a row".
    func testUndoThenReanswerDoesNotCountTwice() {
        let app = launch()
        openDeck(app)
        answerFirstCardRight(app)

        let undo = app.buttons["Undo last answer"]
        XCTAssertTrue(undo.waitForExistence(timeout: 10), "precondition: undo is offered after a swipe")
        tap(undo)
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertTrue(deckHeader(app).label.hasPrefix("0 of "), "precondition: undo put the card back, got \(deckHeader(app).label)")

        answerFirstCardRight(app)
        let known = lockedIn(afterLeavingDeck: app)
        XCTAssertEqual(known, 0, "undo then re-answer is one answer, but the room says \(known) locked in")
    }

    // MARK: - Fix My Mistakes Close

    /// Promise (PracticeRunView.finish): "A run the player quit before answering
    /// anything is not an achievement". Miss three cards, open Fix My Mistakes,
    /// answer one, tap Close: the result should read out of the one answered.
    func testClosingFixMyMistakesEarlyScoresOutOfWhatWasAnswered() {
        let app = launch(member: true)
        openDeck(app)
        for wrong in ["52 cards", "Diamonds only", "Trump only if diamonds are called"] {
            let pick = app.buttons[wrong]
            XCTAssertTrue(pick.waitForExistence(timeout: 15), "precondition: \(wrong) is offered")
            tap(pick)
            let next = app.buttons["Next"]
            XCTAssertTrue(next.waitForExistence(timeout: 15))
            Thread.sleep(forTimeInterval: 1.5)
            tap(next)
            Thread.sleep(forTimeInterval: 1.5)
        }
        app.navigationBars.buttons.firstMatch.tap() // deck -> room
        Thread.sleep(forTimeInterval: 1)
        app.navigationBars.buttons.firstMatch.tap() // room -> Home

        let tile = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Fix My'")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 20), "precondition: Fix My Mistakes tile is on Home")
        XCTAssertTrue(tile.label.contains("3 due"), "precondition: three misses are due, tile says \(tile.label)")
        // The training tiles sit in a sideways scroller; Fix My Mistakes is the last one.
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Timed'")).firstMatch
        var drags = 0
        while tile.frame.maxX > app.frame.width - 8, drags < 6 {
            let y = row.frame.midY
            let from = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: app.frame.width * 0.85, dy: y))
            let to = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: app.frame.width * 0.15, dy: y))
            from.press(forDuration: 0.1, thenDragTo: to)
            Thread.sleep(forTimeInterval: 0.8)
            drags += 1
        }
        tap(tile)

        let counter = app.staticTexts["1 of 3"]
        XCTAssertTrue(counter.waitForExistence(timeout: 15), "precondition: a three item review run")
        let rights = ["32 cards", "Queens, jacks, and diamonds", "Always trump"]
        guard let right = rights.map({ app.buttons[$0] }).first(where: { $0.exists }) else {
            return XCTFail("precondition: no known right answer on screen")
        }
        tap(right)
        let close = app.buttons["Close"]
        XCTAssertTrue(close.waitForExistence(timeout: 10), "precondition: review runs offer Close")
        tap(close)

        let result = app.staticTexts.matching(NSPredicate(format: "label MATCHES '^[0-9]+/[0-9]+$'")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 10), "the run ends on a score screen")
        XCTAssertTrue(result.label.hasSuffix("/1"), "one question answered, the score screen says \(result.label)")
    }

    // MARK: - Helpers

    private func deckHeader(_ app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label ENDSWITH ' down'")).firstMatch
    }

    private func tap(_ element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func openDeck(_ app: XCUIApplication) {
        open("The Card Room", in: app)
        open("Meet the Cards", in: app)
        XCTAssertTrue(deckHeader(app).waitForExistence(timeout: 30), "the deck never opened")
        XCTAssertTrue(deckHeader(app).label.hasPrefix("0 of "), "precondition: fresh deck, got \(deckHeader(app).label)")
    }

    private func answerFirstCardRight(_ app: XCUIApplication) {
        let pick = app.buttons["32 cards"]
        XCTAssertTrue(pick.waitForExistence(timeout: 15), "card one's answer is missing")
        tap(pick)
        let next = app.buttons["Next"]
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        Thread.sleep(forTimeInterval: 1.5)
        tap(next)
        Thread.sleep(forTimeInterval: 3)
    }

    /// Back to the room and read "<Level>, K of N locked in".
    private func lockedIn(afterLeavingDeck app: XCUIApplication) -> Int {
        app.navigationBars.buttons.firstMatch.tap()
        let chip = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS 'locked in'")).firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: 15), "the room shows a mastery chip once practised")
        let label = chip.label
        guard let range = label.range(of: #"(\d+) of \d+ locked in"#, options: .regularExpression),
              let number = label[range].split(separator: " ").first.flatMap({ Int($0) }) else {
            XCTFail("unreadable chip: \(label)")
            return -1
        }
        return number
    }

    private func open(_ label: String, in app: XCUIApplication) {
        var match = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch
        if !match.waitForExistence(timeout: 30) {
            match = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch
            XCTAssertTrue(match.waitForExistence(timeout: 10), "could not find \(label)")
        }
        var swipes = 0
        while match.frame.midY > app.frame.height * 0.85, swipes < 6 {
            app.swipeUp()
            swipes += 1
        }
        tap(match)
    }
}
