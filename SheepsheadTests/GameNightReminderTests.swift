import XCTest
@testable import Sheepshead

/// Audit C2: a member who let Sheepshead+ run out while the app was closed
/// kept the weekly game night reminder, and its only switch is hidden from
/// non-members. Home now drops it whenever a resolved non-member is seen.
@MainActor
final class GameNightReminderTests: XCTestCase {
    private let suite = "GameNightReminderTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
        // Stored, as a member who set it up on an earlier launch left it.
        defaults.set(true, forKey: "settings.gameNightReminderEnabled")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    func testLapsedMemberLosesTheReminderAtLaunch() {
        let settings = AppSettings(defaults: defaults)
        XCTAssertTrue(settings.gameNightReminderEnabled, "precondition: an existing reminder still loads")
        settings.dropGameNightReminderUnlessMember(isMember: false, membershipResolved: true)
        XCTAssertFalse(settings.gameNightReminderEnabled)
        XCTAssertFalse(AppSettings(defaults: defaults).gameNightReminderEnabled, "the off is stored")
    }

    /// Before RevenueCat answers a member reads as free: that is not a lapse.
    func testUnresolvedMembershipKeepsTheReminder() {
        let settings = AppSettings(defaults: defaults)
        settings.dropGameNightReminderUnlessMember(isMember: false, membershipResolved: false)
        XCTAssertTrue(settings.gameNightReminderEnabled)
    }

    func testMemberKeepsTheReminder() {
        let settings = AppSettings(defaults: defaults)
        settings.dropGameNightReminderUnlessMember(isMember: true, membershipResolved: true)
        XCTAssertTrue(settings.gameNightReminderEnabled)
    }
}
