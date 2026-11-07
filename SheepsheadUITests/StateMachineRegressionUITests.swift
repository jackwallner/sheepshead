import XCTest

/// Regression tests for the state machine audit of 2026-11-06 and its review
/// (`project-docs/audits/state-machines-2026-11-06*.md`). Launch arguments
/// blank the stored practice data so every test starts from an empty record.
final class StateMachineRegressionUITests: XCTestCase {

    private func launch(member: Bool = false, extra: [String] = []) -> XCUIApplication {
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
            // Explicit either way: the Settings developer switch stores it.
            "-subscription.localProOverride", member ? "YES" : "NO",
        ] + extra
        app.launch()
        return app
    }

    // MARK: - B1: flashcard Undo takes the answer back

    /// Control: one correct answer on card one is not "locked in".
    func testControlOneAnswerLocksInNothing() {
        let app = launch()
        openDeck(app)
        answerFirstCard(app, with: "32 cards")
        XCTAssertEqual(lockedIn(afterLeavingDeck: app), 0, "one correct answer is not two in a row")
    }

    /// "Undo last answer", then the same answer again, is ONE answer.
    func testUndoThenReanswerDoesNotCountTwice() {
        let app = launch()
        openDeck(app)
        answerFirstCard(app, with: "32 cards")
        undo(app)
        answerFirstCard(app, with: "32 cards")
        let known = lockedIn(afterLeavingDeck: app)
        XCTAssertEqual(known, 0, "undo then re-answer is one answer, but the room says \(known) locked in")
    }

    /// The realistic route: a mistap undone and answered right leaves no miss.
    func testUndoneMistapLeavesNoMissInStats() {
        let app = launch()
        openDeck(app)
        answerFirstCard(app, with: "52 cards")
        undo(app)
        answerFirstCard(app, with: "32 cards")

        app.navigationBars.buttons.firstMatch.tap() // deck -> room
        Thread.sleep(forTimeInterval: 1)
        app.navigationBars.buttons.firstMatch.tap() // room -> Home
        openSettings(app)
        open("Your Progress", in: app)
        XCTAssertTrue(app.staticTexts["answered"].waitForExistence(timeout: 15), "Your Progress never opened")
        XCTAssertTrue(app.staticTexts["100%"].exists, "the undone mistap still counts against accuracy")
        XCTAssertFalse(app.staticTexts["50%"].exists)
    }

    // MARK: - C2: a lapse Home never saw drops the game night reminder

    /// A member set a game night reminder, then the membership ran out while
    /// the app was closed: the first launch already reads as a non-member, so
    /// no membership change is ever observed. The reminder must still go. The
    /// Home tile names the reminder's day while one is set, "Weekly" when not.
    func testLaunchAsLapsedMemberDropsGameNightReminder() {
        let app = launch(member: false, extra: ["-settings.gameNightReminderEnabled", "YES"])
        let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Game Night'")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 30), "precondition: the Game Night Prep tile is on Home")
        Thread.sleep(forTimeInterval: 2)
        XCTAssertTrue(tile.label.contains("Weekly"), "the lapsed member's weekly reminder is still on: \(tile.label)")
    }

    // MARK: - Helpers

    private func openSettings(_ app: XCUIApplication) {
        let gear = app.buttons["Settings"]
        XCTAssertTrue(gear.waitForExistence(timeout: 30), "Home never appeared")
        gear.tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 15), "Settings never opened")
    }

    private func undo(_ app: XCUIApplication) {
        let undo = app.buttons["Undo last answer"]
        XCTAssertTrue(undo.waitForExistence(timeout: 10), "precondition: undo is offered after a swipe")
        tap(undo)
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertTrue(deckHeader(app).label.hasPrefix("0 of "), "precondition: undo put the card back, got \(deckHeader(app).label)")
    }

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

    private func answerFirstCard(_ app: XCUIApplication, with answer: String) {
        let pick = app.buttons[answer]
        XCTAssertTrue(pick.waitForExistence(timeout: 15), "card one's \(answer) is missing")
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
