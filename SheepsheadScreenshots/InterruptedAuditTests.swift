import XCTest

/// Audit capture for a player who is interrupted mid-task and returns later:
/// the app is killed (or sent to the background) in the middle of onboarding,
/// a Get Started session, a flashcard deck and the Timed Challenge, then
/// relaunched. Never calls XCTFail; it records what came back in text
/// attachments next to the screenshots.
@MainActor
final class InterruptedAuditTests: XCTestCase {
    private var app: XCUIApplication!
    private var notes: [String] = []

    private func launch(_ args: [String]) {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = args
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle(2.5)
    }

    private var returningArgs: [String] {
        [
            "-progress.hasOnboarded", "YES",
            "-sheepshead.hasReadPrimer", "YES",
            "-sheepshead.skillLevel", "played",
            "-whatsnew.lastSeenVersion", "1.3.0",
            "-sheepshead.suppressWhatsNew",
        ]
    }

    private func relaunch(_ args: [String]) {
        app.terminate()
        settle(1)
        launch(args)
    }

    override func tearDown() {
        let note = XCTAttachment(string: notes.joined(separator: "\n"))
        note.name = "notes_\(name.replacingOccurrences(of: " ", with: "_"))"
        note.lifetime = .keepAlways
        add(note)
    }

    // MARK: - Onboarding

    /// Fresh install, walk to the trial page, kill, return. Then the same from
    /// the primer and from the tour.
    func testOnboardingKilledAndResumed() {
        let args = ["-whatsnew.lastSeenVersion", "1.3.0", "-sheepshead.suppressWhatsNew"]
        launch(args)
        capture("o01_page0")
        for _ in 0..<3 {
            tap("Continue")
            settle(0.6)
        }
        capture("o02_skill_page")
        _ = open("Brand new")
        capture("o03_skill_picked")
        tap("Continue")
        settle(0.8)
        capture("o04_trial_page")

        // Interruption 1: killed on the trial page.
        relaunch(args)
        capture("o05_after_kill_on_trial_page")
        logVisibleText("after kill on trial page")
        notes.append("first page again: \(app.staticTexts["Make it stick between games"].exists)")

        for _ in 0..<3 {
            tap("Continue")
            settle(0.6)
        }
        capture("o06_skill_page_second_time")
        let selected = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Brand new")).firstMatch
        notes.append("skill choice remembered (selected trait): \(selected.exists && selected.isSelected)")
        tap("Continue")
        settle(0.8)

        // Soft exit into the primer (skill is "new").
        tap("Get Started")
        settle(1.0)
        capture("o07_primer_first_page")
        tap("Continue")
        settle(0.6)
        tap("Continue")
        settle(0.6)
        capture("o08_primer_third_page")

        // Interruption 2: killed three pages into the primer.
        relaunch(args)
        capture("o09_after_kill_in_primer")
        logVisibleText("after kill in primer")
        notes.append("first page again after primer kill: \(app.staticTexts["Make it stick between games"].exists)")

        // Back to the tour the long way.
        for _ in 0..<4 {
            tap("Continue")
            settle(0.6)
        }
        tap("Get Started")
        settle(1.0)
        tap("Skip for now")
        settle(1.0)
        capture("o10_after_primer_skip")
        logVisibleText("after primer skip")
    }

    func testTourKilledAfterSkipTrial() {
        // A returning-onboarding state: a player who answered the question and
        // chose the soft exit, then reached the tour, then was interrupted.
        // The tour is only reachable through the trial page, so walk it with
        // an "experienced" skill pick (no primer).
        let args = ["-whatsnew.lastSeenVersion", "1.3.0", "-sheepshead.suppressWhatsNew",
                    "-sheepshead.skillLevel", "played"]
        launch(args)
        for _ in 0..<4 {
            tap("Continue")
            settle(0.6)
        }
        tap("Get Started")
        settle(1.0)
        capture("t01_tour_page1")
        tap("Show me")
        settle(0.8)
        tap("Show me")
        settle(0.8)
        capture("t02_tour_page3")
        // Interruption: killed on the third tour page.
        relaunch(args)
        capture("t03_after_kill_in_tour")
        logVisibleText("after kill in tour")
        notes.append("first onboarding page again: \(app.staticTexts["Make it stick between games"].exists)")
    }

    // MARK: - Get Started

    func testGetStartedAbandonedHalfway() {
        launch(returningArgs)
        capture("g01_home")
        guard open("Get Started") else { return }
        logVisibleText("session attempt 1 q1")
        capture("g02_first_question")
        for turn in 0..<4 {
            guard answerFirstChoice() else { break }
            if turn == 3 { capture("g03_after_four_answers") }
            guard tapNext() else { break }
        }
        logVisibleText("session attempt 1 q5")
        capture("g04_midway_before_leave")
        back()
        capture("g05_home_after_leaving_midway")
        notes.append("leave prompt shown: \(app.alerts.count > 0 || app.sheets.count > 0)")
        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Get Started")).firstMatch
        notes.append("Get Started card label after abandoning: \(card.exists ? card.label : "-")")

        // Killed rather than left.
        relaunch(returningArgs)
        capture("g06_home_after_kill")
        guard open("Get Started") else { return }
        logVisibleText("session attempt 2 q1")
        capture("g07_second_attempt_first_question")
    }

    // MARK: - Flashcard deck

    func testFlashcardDeckLeftHalfway() {
        launch(returningArgs + ["-subscription.localProOverride", "YES"])
        app.swipeUp()
        settle(0.8)
        guard open("The Card Room") else { return }
        capture("d01_room")
        guard open("Meet the Cards") || open("Rank") || open("Trump") else { return }
        capture("d02_deck_front")
        logVisibleText("deck card 1")
        for _ in 0..<3 {
            flipTopCard()
            swipeTopCard(right: true)
        }
        capture("d03_deck_after_three_swipes")
        logVisibleText("deck after 3")
        back()
        capture("d04_room_after_leaving_deck")
        // Reopen the same deck.
        guard open("Meet the Cards") || open("Rank") || open("Trump") else { return }
        capture("d05_deck_reopened")
        logVisibleText("deck reopened")
    }

    // MARK: - Timed Challenge

    func testTimedChallengeInterrupted() {
        launch(returningArgs + ["-subscription.localProOverride", "YES"])
        guard openTile("Timed") else { return }
        capture("c01_timed_start")
        logVisibleText("timed start")
        _ = answerFirstChoice()
        _ = tapNext()
        capture("c02_timed_after_one")
        let before = timerText()
        notes.append("timer before background: \(before)")

        // Notification-centre style interruption: the app stays alive but
        // inactive, then the player comes back.
        XCUIDevice.shared.press(.home)
        settle(12)
        app.activate()
        settle(1.5)
        let after = timerText()
        notes.append("timer after 12s in background: \(after)")
        capture("c03_timed_after_background")
        logVisibleText("timed after background")

        // Leave mid-run with the back button.
        back()
        settle(0.8)
        capture("c04_after_back_from_timed")
        notes.append("confirmation on leaving timed: \(app.alerts.count > 0 || app.sheets.count > 0)")
        logVisibleText("after leaving timed")
    }

    // MARK: - Helpers

    private func timerText() -> String {
        let match = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", "s")).allElementsBoundByIndex
            .map(\.label).filter { $0.first?.isNumber == true }
        return match.first ?? "-"
    }

    @discardableResult
    private func openTile(_ label: String) -> Bool {
        if open(label, timeout: 2) { return true }
        for _ in 0..<3 {
            app.swipeLeft()
            settle(0.4)
            if open(label, timeout: 1) { return true }
        }
        return false
    }

    @discardableResult
    private func open(_ label: String, timeout: TimeInterval = 6) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            guard match.waitForExistence(timeout: timeout) else { continue }
            match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            return true
        }
        notes.append("could not open: \(label)")
        return false
    }

    @discardableResult
    private func tap(_ label: String) -> Bool {
        let button = app.buttons[label].firstMatch
        guard button.waitForExistence(timeout: 4) else {
            notes.append("could not tap: \(label)")
            return false
        }
        button.tap()
        settle(0.5)
        return true
    }

    @discardableResult
    private func answerFirstChoice() -> Bool {
        let choices = app.scrollViews.buttons
        guard choices.firstMatch.waitForExistence(timeout: 5) else {
            notes.append("no choice to answer")
            return false
        }
        choices.element(boundBy: 0).tap()
        settle(0.8)
        return true
    }

    @discardableResult
    private func tapNext() -> Bool {
        for label in ["Next", "Next Question", "Next Hand", "Finish"] {
            let button = app.buttons[label].firstMatch
            if button.waitForExistence(timeout: 1.5) {
                button.tap()
                settle(0.8)
                return true
            }
        }
        return false
    }

    private func back() {
        let button = app.navigationBars.buttons.element(boundBy: 0)
        if button.exists, button.label != "Settings" {
            button.tap()
            settle(0.7)
        }
    }

    private func flipTopCard() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
        settle(1.0)
    }

    private func swipeTopCard(right: Bool) {
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: right ? 0.3 : 0.7, dy: 0.45))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: right ? 0.95 : 0.05, dy: 0.45))
        from.press(forDuration: 0.1, thenDragTo: to)
        settle(1.0)
    }

    private func logVisibleText(_ tag: String) {
        let texts = app.staticTexts.allElementsBoundByIndex.prefix(14).map(\.label).filter { !$0.isEmpty }
        notes.append("[\(tag)] \(texts.joined(separator: " | "))")
    }

    private func settle(_ seconds: TimeInterval = 1.2) { Thread.sleep(forTimeInterval: seconds) }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
