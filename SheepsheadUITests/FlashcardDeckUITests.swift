import XCTest

/// Drives the real Meet the Cards deck, the Card Room's first drill. It is free
/// and opens with a two-option self-test, so its Next button is on screen the
/// moment the first card is answered.
final class FlashcardDeckUITests: XCTestCase {

    /// The self-test deck's Next button must move exactly one card, however
    /// fast it is tapped. The button stays on the card while it flies off, so a
    /// second tap used to run the commit twice and quietly consume the
    /// following card, grading it right without the player ever seeing it.
    func testDoubleTappingNextAdvancesExactlyOneCard() {
        continueAfterFailure = false
        // Addressed by bundle id, as in PaywallFunnelUITests: PRODUCT_NAME
        // differs from the target name.
        let app = XCUIApplication(bundleIdentifier: "com.jackwallner.sheepshead")
        app.launchArguments += [
            "-progress.hasOnboarded", "YES",
            "-sheepshead.hasReadPrimer", "YES",
            "-sheepshead.skillLevel", "basics",
            "-sheepshead.hasSwipedDeck", "YES",
            "-sheepshead.suppressWhatsNew",
        ]
        app.launch()

        open("The Card Room", in: app)
        open("Meet the Cards", in: app)

        let header = deckHeader(in: app)
        XCTAssertTrue(header.waitForExistence(timeout: 30), "the deck never opened")
        XCTAssertTrue(header.label.hasPrefix("0 of "), "a fresh deck starts at zero, got \(header.label)")

        // The first card asks 32 cards or 52 cards; 32 is right, so exactly
        // one card should read as down once Next lands.
        let pick = app.buttons["32 cards"]
        XCTAssertTrue(pick.waitForExistence(timeout: 15), "the first card's answer button is missing")
        tap(pick)

        let next = app.buttons["Next"]
        XCTAssertTrue(next.waitForExistence(timeout: 15), "Next never appeared after answering")
        // Let the flip land so the button sits where its frame says.
        Thread.sleep(forTimeInterval: 1.5)
        next.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).doubleTap()

        // Let the fling finish and the deck settle before reading the count.
        Thread.sleep(forTimeInterval: 3)
        let settled = deckHeader(in: app)
        XCTAssertTrue(settled.exists, "the deck header disappeared")
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "deck_after_double_tapped_next"
        shot.lifetime = .keepAlways
        add(shot)
        XCTAssertTrue(
            settled.label.hasPrefix("1 of "),
            "one correct answer and one Next should read 1 down, the deck says \(settled.label)"
        )
    }

    // MARK: - Helpers

    private func deckHeader(in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label ENDSWITH ' down'")).firstMatch
    }

    /// Taps the centre of the frame rather than the element: SwiftUI cards
    /// report isHittable false often enough that trusting it costs a whole run
    /// (see ScreenshotTests), and a coordinate tap lands in the same place.
    private func tap(_ element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// Opens a Home or room card by part of its label. Cards are NavigationLinks,
    /// so the label is the whole card, not just the title.
    private func open(_ label: String, in app: XCUIApplication) {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        var match = app.buttons.matching(predicate).firstMatch
        if !match.waitForExistence(timeout: 30) {
            match = app.staticTexts.matching(predicate).firstMatch
            XCTAssertTrue(match.waitForExistence(timeout: 10), "could not find \(label)")
        }
        // Both screens open scrolled to the top, so anything low is below the fold.
        var swipes = 0
        while match.frame.midY > app.frame.height * 0.85, swipes < 6 {
            app.swipeUp()
            swipes += 1
        }
        tap(match)
    }
}
