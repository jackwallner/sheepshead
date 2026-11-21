import XCTest

/// Regression tests for the 2026-11-20 bug catalog
/// (`project-docs/audits/2026-11-20-bug-ux.html`): screens that must follow
/// the wall clock while the app sits in the background.
final class TimeRolloverUITests: XCTestCase {

    private func launch(member: Bool, extra: [String] = [], environment: [String: String] = [:]) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.sheepshead")
        app.launchArguments += [
            "-progress.hasOnboarded", "YES",
            "-sheepshead.hasReadPrimer", "YES",
            "-sheepshead.skillLevel", "basics",
            "-sheepshead.hasSwipedDeck", "YES",
            "-sheepshead.suppressWhatsNew",
            "-subscription.localProOverride", member ? "YES" : "NO",
        ] + extra
        app.launchEnvironment.merge(environment) { $1 }
        app.launch()
        return app
    }

    // MARK: - B3: Home after midnight in the background

    /// Today's Get Started is done, the app goes to the background, midnight
    /// passes, the player comes back: Home must offer a fresh Get Started.
    ///
    /// The app runs in a fixed-offset zone picked so its local clock reads
    /// about 23:57:30 at launch, so the test waits two or three minutes, not a day.
    func testHomeOffersAFreshSessionAfterMidnightInTheBackground() throws {
        let now = Date()
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let parts = utc.dateComponents([.hour, .minute, .second], from: now)
        let utcMinutes = Double(parts.hour! * 60 + parts.minute!) + Double(parts.second!) / 60
        var offset = Int((23 * 60 + 57.5 - utcMinutes).rounded())
        if offset > 14 * 60 { offset -= 24 * 60 }
        if offset < -12 * 60 { offset += 24 * 60 }
        let sign = offset < 0 ? "-" : "+"
        let name = String(format: "GMT%@%02d%02d", sign, abs(offset) / 60, abs(offset) % 60)
        let zone = try XCTUnwrap(TimeZone(identifier: name))

        var local = Calendar(identifier: .gregorian)
        local.timeZone = zone
        let todayMidnight = local.startOfDay(for: now)
        let nextMidnight = local.date(byAdding: .day, value: 1, to: todayMidnight)!
        XCTAssertGreaterThan(nextMidnight.timeIntervalSince(now), 90, "precondition: launch lands before local midnight")
        XCTAssertLessThan(nextMidnight.timeIntervalSince(now), 210)

        // Get Started done today, as a build before the 2026-11-20 fixes
        // stored it (that day's local midnight); current builds read both.
        let stamp = ISO8601DateFormatter().string(from: todayMidnight)
        let plist = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><plist version=\"1.0\"><date>\(stamp)</date></plist>"
        let app = launch(member: false, extra: ["-progress.lastQuickSessionDay", plist], environment: ["TZ": name])

        let done = app.staticTexts["Today's session is done"]
        XCTAssertTrue(done.waitForExistence(timeout: 30), "precondition: Home shows today's session as done")

        sendToBackground(app)
        waitInBackground(app, until: nextMidnight.addingTimeInterval(5))
        app.activate()
        note("back: done card showing \(done.exists)")

        XCTAssertTrue(app.staticTexts["Get Started"].waitForExistence(timeout: 10),
                      "after midnight Home still says today's session is done")
        XCTAssertFalse(done.exists)
    }

    // MARK: - B7: the Timed Challenge clock in the background

    /// The 90 second clock is wall time: time spent in another app counts.
    func testTimedChallengeClockRunsWhileInTheBackground() {
        let app = launch(member: true)
        let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Timed'")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 30), "the Timed Challenge tile is on Home")
        var swipes = 0
        while !tile.isHittable, swipes < 4 {
            app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Endless'")).firstMatch.swipeLeft()
            swipes += 1
        }
        tile.tap()

        let before = secondsLeft(app)
        XCTAssertGreaterThan(before, 60, "precondition: a fresh run, got \(before)s")

        sendToBackground(app)
        waitInBackground(app, until: Date().addingTimeInterval(35))
        app.activate()
        Thread.sleep(forTimeInterval: 2)

        let after = secondsLeft(app)
        note("clock \(before)s before, \(after)s after 35s away")
        XCTAssertLessThanOrEqual(after, before - 30, "35 seconds away cost the clock \(before - after)s")
    }

    /// Opens the Settings app over ours. `press(.home)` left the app in the
    /// foreground on the headless iOS 27 simulator.
    private func sendToBackground(_ app: XCUIApplication) {
        XCUIApplication(bundleIdentifier: "com.apple.Preferences").activate()
        XCTAssertTrue(app.wait(for: .runningBackgroundSuspended, timeout: 20) || app.state == .runningBackground,
                      "precondition: the app left the foreground, state \(app.state.rawValue)")
        note("sent to background: app state \(app.state.rawValue)")
    }

    /// Sleeps, logging the app's process state every ten seconds: whether
    /// iOS suspended it is what decides both bugs.
    private func waitInBackground(_ app: XCUIApplication, until end: Date) {
        while end.timeIntervalSinceNow > 0 {
            Thread.sleep(forTimeInterval: min(10, max(0, end.timeIntervalSinceNow)))
            note("background: app state \(app.state.rawValue)")
        }
    }

    private func note(_ text: String) {
        XCTContext.runActivity(named: text) { _ in }
    }

    private func secondsLeft(_ app: XCUIApplication) -> Int {
        let clock = app.staticTexts.matching(NSPredicate(format: "label MATCHES '^[0-9]+s$'")).firstMatch
        XCTAssertTrue(clock.waitForExistence(timeout: 15), "the challenge clock is missing")
        return Int(clock.label.dropLast()) ?? -1
    }
}
