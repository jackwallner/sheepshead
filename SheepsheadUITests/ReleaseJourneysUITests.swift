import XCTest

/// Release-gate journeys (qa-gate). They prove screens are reachable and the
/// core loop survives a relaunch; FleetQA's oracles judge what is on screen.
///
/// RevenueCat is never configured on a simulator, so the paywalls draw without
/// live prices here. Nothing in this file reaches the production `appl_` key.
@MainActor
final class ReleaseJourneysUITests: XCTestCase {
    private var app: XCUIApplication!

    /// Past onboarding, the primer and What's New, so a journey starts on Home.
    private let onboarded = [
        "-progress.hasOnboarded", "YES",
        "-sheepshead.hasReadPrimer", "YES",
        "-sheepshead.skillLevel", "basics",
        "-sheepshead.hasSwipedDeck", "YES",
        "-sheepshead.suppressWhatsNew",
        // Earlier UI test classes launch the app, so by here it is past the
        // second launch and Apple's rating prompt can cover Done.
        "-sheepshead.rc.rating_prompt", "off",
        // Explicit: the Settings developer switch stores it.
        "-subscription.localProOverride", "NO",
    ]

    override func setUp() {
        continueAfterFailure = false
        // By bundle id: the target name differs from PRODUCT_NAME.
        app = XCUIApplication(bundleIdentifier: "com.jackwallner.sheepshead")
    }

    // MARK: - Journeys

    func testFirstRunToFirstQuestion() {
        QA.launch(app, arguments: ["-sheepshead.suppressWhatsNew", "-sheepshead.rc.rating_prompt", "off"])
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 20), "onboarding did not appear")
        QA.checkpoint(app, "onboarding-welcome")

        for page in 2...3 {
            tap("Continue")
            QA.checkpoint(app, "onboarding-page-\(page)")
        }
        tap("Continue")
        XCTAssertTrue(app.staticTexts["Where are you starting from?"].waitForExistence(timeout: 10))
        QA.checkpoint(app, "onboarding-skill-level")

        tap("Know the basics", prefix: true)
        tap("Continue")
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 10), "trial page did not appear")
        QA.checkpoint(app, "onboarding-trial-pitch")

        // The free exit is drawn on screen but XCTest reports it unhittable
        // (gh-sim run sheepshead-mbairbc70-1122-125708-20969), so press it
        // where it is drawn, as a finger would.
        let getStarted = app.buttons["Get Started"]
        // At accessibility sizes it sits inside the scrolling page, below the fold.
        _ = QA.reveal(getStarted, in: app)
        if getStarted.isHittable {
            getStarted.tap()
        } else {
            getStarted.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        XCTAssertTrue(app.buttons["Show me"].waitForExistence(timeout: 10), "the feature tour did not appear")
        QA.checkpoint(app, "tour-first-page")
        for step in 1...8 {
            if app.buttons["Start my first session"].exists { break }
            tap("Show me")
            QA.checkpoint(app, "tour-\(step)")
        }
        tap("Start my first session")
        XCTAssertTrue(counter().waitForExistence(timeout: 15), "the first question did not appear")
        QA.checkpoint(app, "first-question")

        tap("Close")
        XCTAssertTrue(app.staticTexts["THE ROOMS"].waitForExistence(timeout: 15), "Home did not appear")
        QA.checkpoint(app, "home-after-first-run")
    }

    func testPaywallShownAndDismissed() {
        QA.launch(app, arguments: onboarded)
        XCTAssertTrue(app.staticTexts["THE ROOMS"].waitForExistence(timeout: 20))
        QA.checkpoint(app, "home")

        let upgrade = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Get Sheepshead+")).firstMatch
        QA.tap(upgrade, in: app, "Get Sheepshead+")
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 10), "the paywall did not appear")
        QA.checkpoint(app, "paywall")

        app.buttons["Close"].tap()
        XCTAssertTrue(app.staticTexts["THE ROOMS"].waitForExistence(timeout: 10), "Home did not return")
        QA.checkpoint(app, "paywall-dismissed")
    }

    func testReturnVisitOpensARoom() {
        QA.launch(app, arguments: onboarded)
        XCTAssertTrue(app.staticTexts["THE ROOMS"].waitForExistence(timeout: 20))
        QA.relaunch(app)
        XCTAssertTrue(app.staticTexts["THE ROOMS"].waitForExistence(timeout: 20), "Home did not return on a second launch")
        QA.checkpoint(app, "home-return-visit")

        let room = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "The Card Room")).firstMatch
        QA.tap(room, in: app, "The Card Room")
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 10), "the room did not open")
        XCTAssertTrue(app.staticTexts["THE ROOMS"].waitForNonExistence(timeout: 10), "still on Home after opening a room")
        QA.checkpoint(app, "room")
    }

    func testInterruptedSessionKeepsItsAnswer() {
        // The core-loop journey spends today's session on the shared install;
        // the launch argument shadows the stored day so Get Started is offered.
        QA.launch(app, arguments: onboarded + ["-progress.lastQuickSessionDay", "2000-01-01"])
        startSession()
        QA.checkpoint(app, "session-question")

        answerCurrentQuestion()
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 10))
        QA.checkpoint(app, "session-answered")

        QA.interrupt(app)
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 10), "the graded question was lost after backgrounding")
        QA.checkpoint(app, "session-after-interrupt")

        QA.tap(app.buttons["Next"], in: app, "Next")
        XCTAssertTrue(counter().waitForExistence(timeout: 10), "the session did not continue")
        QA.checkpoint(app, "session-second-question")
    }

    /// The app's main job: finish a Get Started session and have it count.
    func testCoreLoopSessionCountsAndSurvivesRelaunch() {
        QA.launch(app, arguments: onboarded)
        XCTAssertTrue(app.staticTexts["THE ROOMS"].waitForExistence(timeout: 20))
        XCTAssertFalse(home("Today's session is done").exists, "a fresh install already has a finished session")
        let before = drillsDone()
        XCTAssertNotNil(before, "Home should show the drills done chip")

        startSession()
        QA.checkpoint(app, "session-first-question")

        var answered = 0
        while true {
            let (index, total) = progress()
            answerCurrentQuestion()
            answered += 1
            if answered == 1 { QA.checkpoint(app, "session-first-answered") }
            let last = index == total
            let advance = app.buttons[last ? "Finish" : "Next"]
            XCTAssertTrue(advance.waitForExistence(timeout: 10), "no \(last ? "Finish" : "Next") after question \(index)")
            if last { QA.checkpoint(app, "session-last-answered") }
            QA.tap(advance, in: app, last ? "Finish" : "Next")
            if last { break }
            XCTAssertTrue(counter().waitForExistence(timeout: 10), "question \(index + 1) did not appear")
        }
        XCTAssertGreaterThan(answered, 1, "the session had a single question")

        let score = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+/\\d+")).firstMatch
        XCTAssertTrue(score.waitForExistence(timeout: 10), "the finished session showed no score")
        XCTAssertTrue(score.label.hasSuffix("/\(answered)"), "the score \(score.label) does not match \(answered) questions")
        let streakLine = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "[1-9][0-9]*-day streak")).firstMatch
        XCTAssertTrue(streakLine.exists, "the completion screen did not show the streak")
        QA.checkpoint(app, "session-complete")

        QA.tap(app.buttons["Done"], in: app, "Done")
        XCTAssertTrue(home("Today's session is done").waitForExistence(timeout: 15), "Home still offers today's session")
        let after = drillsDone()
        XCTAssertEqual(after, (before ?? 0) + 1, "the finished session was not counted")
        XCTAssertGreaterThanOrEqual(streak() ?? 0, 1, "the streak did not start")
        QA.checkpoint(app, "home-after-session")

        QA.relaunch(app)
        XCTAssertTrue(app.staticTexts["THE ROOMS"].waitForExistence(timeout: 20))
        XCTAssertTrue(home("Today's session is done").waitForExistence(timeout: 10), "today's session reset after relaunch")
        XCTAssertEqual(drillsDone(), after, "the drill count did not survive relaunch")
        XCTAssertGreaterThanOrEqual(streak() ?? 0, 1, "the streak did not survive relaunch")
        QA.checkpoint(app, "home-after-relaunch")
    }

    // MARK: - Helpers

    /// Any element on Home carrying this text (the stat chips merge into one link).
    private func home(_ text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    /// The number before `suffix` in Home's stat chips ("3 drills done", "2 day streak").
    private func chipValue(_ suffix: String) -> Int? {
        let chip = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label MATCHES %@", ".*(^|, )[0-9]+ \(suffix).*")).firstMatch
        guard chip.waitForExistence(timeout: 10) else { return nil }
        let label = chip.label
        guard let range = label.range(of: "[0-9]+ \(suffix)", options: .regularExpression) else { return nil }
        return Int(label[range].split(separator: " ").first ?? "")
    }

    private func drillsDone() -> Int? { chipValue("drills done") }

    private func streak() -> Int? { chipValue("day streak") }

    private func tap(_ text: String, prefix: Bool = false, timeout: TimeInterval = 10) {
        let button = prefix
            ? app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", text)).firstMatch
            : app.buttons[text]
        QA.tap(button, in: app, text, timeout: timeout)
    }

    private func startSession() {
        let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Get Started")).firstMatch
        QA.tap(card, in: app, "the Get Started card")
        XCTAssertTrue(counter().waitForExistence(timeout: 15), "the session did not start")
    }

    /// The "3 of 10" label under the open question.
    private func counter() -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+ of \\d+")).firstMatch
    }

    private func progress() -> (index: Int, total: Int) {
        let parts = counter().label.components(separatedBy: " of ").compactMap { Int($0) }
        XCTAssertEqual(parts.count, 2, "unreadable progress label \(counter().label)")
        return (parts.first ?? 0, parts.last ?? 0)
    }

    /// Taps the first answer row: the buttons between the navigation bar and
    /// the counter. At large text the rows can sit below the fold, so fall
    /// back to the first button in the question's scroll view.
    private func answerCurrentQuestion() {
        let top = app.navigationBars.firstMatch.frame.maxY
        let bottom = counter().frame.minY
        let rows = app.buttons.allElementsBoundByIndex.filter {
            !$0.label.isEmpty && $0.frame.minY >= top && $0.frame.maxY <= bottom && $0.isHittable
        }
        if let row = rows.first {
            row.tap()
            return
        }
        let fallback = app.scrollViews.firstMatch.buttons.firstMatch
        QA.tap(fallback, in: app, "an answer row")
    }
}
