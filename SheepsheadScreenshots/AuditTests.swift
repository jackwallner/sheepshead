import XCTest

/// Audit capture for the generated-practice and progress screens: a standard
/// run and a largest-accessibility-text run. Like `ScreenshotTests` it never
/// calls XCTFail, so one run reports everything it could not reach.
@MainActor
final class AuditTests: XCTestCase {
    private var app: XCUIApplication!
    private var problems: [String] = []

    private func launch(largeText: Bool) {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = [
            "-progress.hasOnboarded", "YES",
            "-sheepshead.hasReadPrimer", "YES",
            "-sheepshead.skillLevel", "some",
            "-subscription.localProOverride", "YES",
            "-whatsnew.lastSeenVersion", ProcessInfo.processInfo.environment["SCREENSHOT_APP_VERSION"] ?? "1.2.4",
        ]
        if largeText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
    }

    func testStandardText() { run(prefix: "std", largeText: false) }
    func testLargeText() { run(prefix: "xxxl", largeText: true) }

    private func run(prefix: String, largeText: Bool) {
        launch(largeText: largeText)
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
        capture("\(prefix)_home")

        if open("Endless") {
            capture("\(prefix)_endless_picker")
            for skill in ["Who Takes the Trick?", "Count the Points", "Read the Holding"] {
                if open(skill) {
                    capture("\(prefix)_\(skill.prefix(5))_question")
                    for turn in 0..<6 where answerFirstChoice() {
                        if turn == 0 { capture("\(prefix)_\(skill.prefix(5))_answered") }
                        tapNext()
                    }
                    back()
                }
            }
            back()
        }

        if open("Trick Room") || open("The Trick Room") {
            capture("\(prefix)_trick_room")
            back()
        }

        if open("day streak") || open("drills done") {
            capture("\(prefix)_progress")
            app.swipeUp()
            settle(0.8)
            capture("\(prefix)_progress_lower")
        }

        if !problems.isEmpty {
            let note = XCTAttachment(string: problems.joined(separator: "\n"))
            note.name = "\(prefix)_problems"
            note.lifetime = .keepAlways
            add(note)
        }
    }

    @discardableResult
    private func open(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            guard match.waitForExistence(timeout: 5) else { continue }
            match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            return true
        }
        problems.append("could not open: \(label)")
        return false
    }

    private func answerFirstChoice() -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS ' of ' OR label CONTAINS 'points' OR label CONTAINS 'Trump' OR label CONTAINS 'Fail'")
        let choice = app.buttons.matching(predicate).firstMatch
        guard choice.waitForExistence(timeout: 4) else {
            problems.append("no choice to answer")
            return false
        }
        choice.tap()
        settle(0.8)
        return true
    }

    private func tapNext() {
        let next = app.buttons["Next"].firstMatch
        if next.waitForExistence(timeout: 3) {
            next.tap()
            settle(0.8)
        }
    }

    private func back() {
        let done = app.buttons["Done"].firstMatch
        if done.exists { done.tap(); settle(0.6) }
        let button = app.navigationBars.buttons.element(boundBy: 0)
        if button.exists, button.identifier != "gearshape" { button.tap(); settle(0.6) }
    }

    private func settle(_ seconds: TimeInterval = 1.4) { Thread.sleep(forTimeInterval: seconds) }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
