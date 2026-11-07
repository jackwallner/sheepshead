import XCTest
@testable import Sheepshead

/// Audit C2: a member who let Sheepshead+ run out while the app was closed
/// kept the weekly game night reminder, and its only switch is hidden from
/// non-members. Home now drops it on a fresh "not a member", never on the
/// launch cache, which reads a member who renewed while closed as lapsed.
@MainActor
final class GameNightReminderTests: XCTestCase {
    private let suite = "GameNightReminderTests"
    private var defaults: UserDefaults!
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 86_400

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

    private func confirms(active: Bool, answeredAt: Date, cache: Date) -> Bool {
        SubscriptionService.confirmsNoMembership(
            isActive: active,
            answeredAt: answeredAt,
            launchCacheAnsweredAt: cache,
            now: now
        )
    }

    func testConfirmedLapseDropsTheReminder() {
        let settings = AppSettings(defaults: defaults)
        XCTAssertTrue(settings.gameNightReminderEnabled, "precondition: an existing reminder still loads")
        settings.dropGameNightReminderUnlessMember(lapseConfirmed: true)
        XCTAssertFalse(settings.gameNightReminderEnabled)
        XCTAssertFalse(AppSettings(defaults: defaults).gameNightReminderEnabled, "the off is stored")
    }

    func testUnconfirmedLapseKeepsTheReminder() {
        let settings = AppSettings(defaults: defaults)
        settings.dropGameNightReminderUnlessMember(lapseConfirmed: false)
        XCTAssertTrue(settings.gameNightReminderEnabled)
    }

    /// The verify route: a monthly member renews while the app is closed and
    /// launches four days later. The cached record reads inactive, then the
    /// network says active. The reminder must survive both.
    func testStaleInactiveCacheThenActiveKeepsARenewedMembersReminder() {
        let settings = AppSettings(defaults: defaults)
        let cacheDate = now.addingTimeInterval(-4 * day)
        let cached = confirms(active: false, answeredAt: cacheDate, cache: cacheDate)
        XCTAssertFalse(cached, "a four-day-old cached record is not a fresh answer")
        settings.dropGameNightReminderUnlessMember(lapseConfirmed: cached)
        let network = confirms(active: true, answeredAt: now, cache: cacheDate)
        settings.dropGameNightReminderUnlessMember(lapseConfirmed: network)
        XCTAssertTrue(settings.gameNightReminderEnabled)
        XCTAssertTrue(AppSettings(defaults: defaults).gameNightReminderEnabled)
    }

    /// The audit route: the membership really ran out while the app was
    /// closed. The network answer after the stale cache drops the reminder.
    func testStaleInactiveCacheThenNetworkInactiveDropsTheReminder() {
        let settings = AppSettings(defaults: defaults)
        let cacheDate = now.addingTimeInterval(-4 * day)
        settings.dropGameNightReminderUnlessMember(
            lapseConfirmed: confirms(active: false, answeredAt: cacheDate, cache: cacheDate)
        )
        XCTAssertTrue(settings.gameNightReminderEnabled)
        settings.dropGameNightReminderUnlessMember(
            lapseConfirmed: confirms(active: false, answeredAt: now.addingTimeInterval(-1), cache: cacheDate)
        )
        XCTAssertFalse(settings.gameNightReminderEnabled)
    }

    func testFreshnessRules() {
        let cacheDate = now.addingTimeInterval(-4 * day)
        XCTAssertFalse(confirms(active: true, answeredAt: now, cache: .distantPast), "a member is never a lapse")
        XCTAssertTrue(confirms(active: false, answeredAt: cacheDate, cache: .distantPast),
                      "no cache at launch: any record is a network answer")
        XCTAssertTrue(confirms(active: false, answeredAt: cacheDate.addingTimeInterval(60), cache: cacheDate),
                      "newer than the launch cache is a network answer, even on a wrong clock")
        XCTAssertTrue(confirms(active: false, answeredAt: now.addingTimeInterval(-60), cache: now.addingTimeInterval(-60)),
                      "a cache answered a minute ago is still fresh")
        XCTAssertFalse(confirms(active: false, answeredAt: now.addingTimeInterval(4 * day), cache: now.addingTimeInterval(4 * day)),
                       "a clock running behind does not make an old cache fresh")
    }
}
