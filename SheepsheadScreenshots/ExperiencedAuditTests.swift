import XCTest

/// Audit capture for an experienced player repeating the core loop: Timed
/// Challenge, Endless Practice, the Bury drill, a flashcard deck, Progress and
/// the free tier. Never calls XCTFail; it records timings and what it could not
/// reach in text attachments next to the screenshots.
@MainActor
final class ExperiencedAuditTests: XCTestCase {
    private var app: XCUIApplication!
    private var notes: [String] = []

    private func launch(member: Bool, extra: [String] = []) {
        continueAfterFailure = true
        app = XCUIApplication()
        var args = [
            "-progress.hasOnboarded", "YES",
            "-sheepshead.hasReadPrimer", "YES",
            "-sheepshead.skillLevel", "played",
            "-whatsnew.lastSeenVersion", "1.3.0",
            "-sheepshead.suppressWhatsNew",
        ]
        if member { args += ["-subscription.localProOverride", "YES"] }
        app.launchArguments = args + extra
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle(2.5)
    }

    override func tearDown() {
        let note = XCTAttachment(string: notes.joined(separator: "\n"))
        note.name = "notes_\(name.replacingOccurrences(of: " ", with: "_"))"
        note.lifetime = .keepAlways
        add(note)
    }

    // MARK: - Member loop

    func testMemberTimedAndEndless() {
        launch(member: true)
        capture("m01_home_top")
        app.swipeUp()
        settle(0.8)
        capture("m02_home_scrolled")
        app.swipeDown()
        settle(0.6)

        // Timed Challenge, run to the clock.
        if openTile("Timed") {
            capture("m03_timed_first_question")
            runTimedUntilDone()
            capture("m06_timed_complete")
            tapDone()
        }
        capture("m07_home_after_timed")

        // Endless: Read the Trump, then Who Takes the Trick.
        if openTile("Endless") {
            capture("m08_endless_picker")
            if open("Read the Trump") {
                answerQuestions(count: 12, prefix: "trump", captureAt: [0, 1])
                finishEndless()
                capture("m11_endless_complete")
                tapDone()
                capture("m12_picker_after_done")
            }
            if open("Who Takes the Trick") {
                answerQuestions(count: 3, prefix: "winner", captureAt: [0])
                finishEndless()
                tapDone()
            }
            if open("Count the Points") {
                answerQuestions(count: 2, prefix: "points", captureAt: [0])
                finishEndless()
                tapDone()
            }
            back()
        }
        capture("m13_home_after_endless")

        // Progress, from the stat chips.
        if open("drills done") || open("day streak") {
            capture("m14_progress_top")
            app.swipeUp()
            settle(0.8)
            capture("m15_progress_lower")
            back()
        }

        // Settings.
        let gear = app.buttons["Settings"].firstMatch
        if gear.waitForExistence(timeout: 3) {
            gear.tap()
            settle()
            capture("m16_settings")
            app.swipeUp()
            settle(0.6)
            capture("m17_settings_lower")
            tapDone()
        }
    }

    func testMemberBuryAndDeck() {
        launch(member: true)
        app.swipeUp()
        settle(0.8)
        if open("The Bury Room") {
            capture("b01_bury_room")
            if open("Choose Your Bury") {
                capture("b02_bury_question")
                selectBuryCards(["K of Clubs", "8 of Spades"])
                capture("b03_bury_selected")
                if tap("Bury These 2") {
                    capture("b04_bury_graded")
                    app.swipeUp()
                    settle(0.6)
                    capture("b05_bury_graded_lower")
                    if tap("Next Holding") { capture("b06_bury_second") }
                }
                // Back out mid-run: is anything preserved?
                back()
                if open("Choose Your Bury") {
                    capture("b07_bury_reopened")
                    back()
                }
            }
            if open("Bury Playbook") {
                capture("b08_deck_front")
                flipTopCard()
                capture("b09_deck_flipped")
                swipeTopCard(right: true)
                capture("b10_deck_after_swipe")
                let undo = app.buttons["Undo last answer"].firstMatch
                notes.append("undo button visible after swipe: \(undo.exists)")
                if undo.exists { undo.tap(); settle(0.8); capture("b11_deck_after_undo") }
                back()
            }
            if open("Choose Your Bury: Extra Reps") {
                capture("b12_bury_extras")
                back()
            }
            back()
        }
        if open("The Trick Room") {
            if open("Trick Judgment") {
                capture("b13_trick_front")
                if tap("Follow clubs") {
                    capture("b14_trick_graded")
                    notes.append("choice card Next button visible: \(app.buttons["Next"].exists)")
                }
                back()
            }
            back()
        }
    }

    // MARK: - Free tier

    func testFreeExperiencedPlayer() {
        launch(member: false)
        capture("f01_home_top")
        app.swipeUp()
        settle(0.8)
        capture("f02_home_scrolled")
        app.swipeDown()
        settle(0.6)

        // A full Get Started, always the first choice, logging every prompt.
        if open("Get Started") {
            for turn in 0..<10 {
                logVisibleText("quick q\(turn + 1)")
                if turn == 0 { capture("f03_quick_first") }
                guard answerFirstChoice() else { break }
                if turn == 0 { capture("f04_quick_first_answered") }
                guard tapNext() else { break }
            }
            capture("f05_quick_complete")
            tapDone()
        }
        capture("f06_home_after_quick")
        app.swipeDown()

        // The training tiles for a free player, and where Fix My Mistakes sits.
        if open("Endless") {
            capture("f07_paywall_from_endless")
            dismissSheet()
        }
        let due = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Fix My")).firstMatch
        notes.append("Fix My Mistakes tile present after one session: \(due.exists) label=\(due.exists ? due.label : "-")")
        if due.exists {
            due.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            capture("f08_paywall_from_fix_mistakes")
            dismissSheet()
        }

        // Re-run the same free quiz twice: same order, same positions?
        app.swipeUp()
        settle(0.6)
        if open("The Card Room") {
            capture("f09_card_room_free")
            for run in 1...2 {
                if open("Card Check") {
                    logVisibleText("cardcheck run\(run) q1")
                    _ = answerFirstChoice()
                    _ = tapNext()
                    logVisibleText("cardcheck run\(run) q2")
                    back()
                }
            }
            back()
        }
    }

    // MARK: - Timed / Endless helpers

    private func runTimedUntilDone() {
        let started = Date()
        var answered = 0
        var perQuestion: [TimeInterval] = []
        while Date().timeIntervalSince(started) < 130 {
            if app.buttons["Done"].firstMatch.exists { break }
            let questionStart = Date()
            guard answerFirstChoice(settleAfter: 0.05) else { break }
            answered += 1
            if answered == 1 { capture("m04_timed_answered") }
            if answered == 3 { capture("m05_timed_third") }
            guard tapNext(settleAfter: 0.05) else { break }
            perQuestion.append(Date().timeIntervalSince(questionStart))
        }
        let mean = perQuestion.isEmpty ? 0 : perQuestion.reduce(0, +) / Double(perQuestion.count)
        notes.append("timed: answered \(answered) in \(Int(Date().timeIntervalSince(started)))s wall, mean pick+Next \(String(format: "%.2f", mean))s (automation overhead included)")
        _ = app.buttons["Done"].firstMatch.waitForExistence(timeout: 10)
        settle(1.0)
    }

    private func answerQuestions(count: Int, prefix: String, captureAt: Set<Int>) {
        for turn in 0..<count {
            logVisibleText("\(prefix) q\(turn + 1)")
            if captureAt.contains(turn) { capture("m09_\(prefix)_q\(turn + 1)") }
            guard answerFirstChoice() else { break }
            if captureAt.contains(turn) { capture("m10_\(prefix)_q\(turn + 1)_answered") }
            guard tapNext() else { break }
        }
    }

    private func finishEndless() {
        let finish = app.buttons["Finish"].firstMatch
        if finish.waitForExistence(timeout: 3) { finish.tap(); settle(1.2) } else { notes.append("no Finish button") }
    }

    @discardableResult
    private func answerFirstChoice(settleAfter: TimeInterval = 0.8) -> Bool {
        let choices = app.scrollViews.buttons
        guard choices.firstMatch.waitForExistence(timeout: 5) else {
            notes.append("no choice to answer")
            return false
        }
        let labels = choices.allElementsBoundByIndex.prefix(6).map(\.label)
        notes.append("choices: \(labels.joined(separator: " / "))")
        choices.element(boundBy: 0).tap()
        settle(settleAfter)
        return true
    }

    @discardableResult
    private func tapNext(settleAfter: TimeInterval = 0.8) -> Bool {
        for label in ["Next", "Next Question", "Next Hand", "Finish"] {
            let button = app.buttons[label].firstMatch
            if button.waitForExistence(timeout: 1.5) {
                button.tap()
                settle(settleAfter)
                return true
            }
        }
        return false
    }

    private func logVisibleText(_ tag: String) {
        let texts = app.staticTexts.allElementsBoundByIndex.prefix(14).map(\.label).filter { !$0.isEmpty }
        notes.append("[\(tag)] \(texts.joined(separator: " | "))")
    }

    // MARK: - Navigation helpers

    @discardableResult
    private func openTile(_ label: String) -> Bool {
        if open(label, timeout: 2) { return true }
        // The training row scrolls sideways; look further along it.
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
        settle()
        return true
    }

    private func tapDone() {
        let done = app.buttons["Done"].firstMatch
        if done.waitForExistence(timeout: 3) { done.tap(); settle(0.8) }
    }

    private func dismissSheet() {
        for label in ["Close", "Not now", "Maybe later", "Done"] {
            let button = app.buttons[label].firstMatch
            if button.exists { button.tap(); settle(0.8); return }
        }
        app.swipeDown(velocity: .fast)
        settle(0.8)
    }

    private func back() {
        let button = app.navigationBars.buttons.element(boundBy: 0)
        if button.exists, button.identifier != "gearshape", button.label != "Settings" {
            button.tap()
            settle(0.7)
        }
    }

    private func selectBuryCards(_ labels: [String]) {
        for label in labels {
            let card = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
            if card.waitForExistence(timeout: 2) {
                card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                settle(0.3)
            } else {
                notes.append("bury card not found: \(label)")
            }
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

    private func settle(_ seconds: TimeInterval = 1.2) { Thread.sleep(forTimeInterval: seconds) }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
