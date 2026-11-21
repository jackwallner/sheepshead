import XCTest
@testable import Sheepshead

/// Regression tests for the 2026-11-20 bug catalog
/// (`project-docs/audits/2026-11-20-bug-ux.html`): day math across a time
/// zone change, a stale membership cache, and the Minute's week.
///
/// `Calendar.current` cannot be switched inside a unit test, so the stored
/// day is seeded as a build before the fix wrote it nine hours east of the
/// test runner (midnight there), and read back in the runner's zone.
@MainActor
final class TimeStateTests: XCTestCase {
    private let suite = "TimeStateTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    // MARK: - Flying west (B1, B5)

    private var reader: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    /// Nine hours east of the runner: Tokyo for a runner on UTC.
    private var writer: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        let offset = TimeZone.current.secondsFromGMT(for: Date(timeIntervalSince1970: 1_773_100_000))
        calendar.timeZone = TimeZone(secondsFromGMT: offset + 9 * 3600)!
        return calendar
    }

    private func date(_ calendar: Calendar, day: Int, hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: day, hour: hour))!
    }

    /// What a build before the fix stored after a drill on March 10, 8 pm,
    /// in the eastern zone: that day's midnight there.
    private var eastMidnightMarch10: Date {
        writer.startOfDay(for: date(writer, day: 10, hour: 20))
    }

    func testStreakNotCountedTwiceForOneDayAfterFlyingWest() {
        defaults.set(eastMidnightMarch10, forKey: "progress.lastActiveDay")
        defaults.set(1, forKey: "progress.streakCount")
        let store = ProgressStore(defaults: defaults)

        store.recordSession(drillID: "a", now: date(reader, day: 10, hour: 18))

        XCTAssertEqual(store.streakCount, 1, "a second drill on March 10 grew the streak")
    }

    func testStreakSurvivesConsecutiveDaysAfterFlyingWest() {
        defaults.set(eastMidnightMarch10, forKey: "progress.lastActiveDay")
        defaults.set(1, forKey: "progress.streakCount")
        let store = ProgressStore(defaults: defaults)
        let march11 = date(reader, day: 11, hour: 10)

        XCTAssertEqual(store.currentStreak(now: march11), 1, "March 10 to 11 is one day, the streak is still alive")
        store.recordSession(drillID: "a", now: march11)
        XCTAssertEqual(store.streakCount, 2)
    }

    func testGetStartedStaysDoneTheSameDayAfterFlyingWest() {
        defaults.set(eastMidnightMarch10, forKey: "progress.lastQuickSessionDay")
        let store = ProgressStore(defaults: defaults)

        XCTAssertTrue(store.quickSessionCompletedToday(now: date(reader, day: 10, hour: 18)))
        XCTAssertFalse(store.quickSessionCompletedToday(now: date(reader, day: 11, hour: 8)))
    }

    /// Days stored by current builds are day keys, so a zone change does not
    /// move them, even for a trip longer than twelve hours.
    func testStoredDayKeysSurviveAZoneChange() {
        for hours in [9, 13] {
            defaults.removePersistentDomain(forName: suite)
            var east = Calendar(identifier: .gregorian)
            let offset = TimeZone.current.secondsFromGMT(for: Date(timeIntervalSince1970: 1_773_100_000))
            east.timeZone = TimeZone(secondsFromGMT: offset + hours * 3600)!
            let store = ProgressStore(defaults: defaults)
            let march10East = date(east, day: 10, hour: 20)
            store.recordSession(drillID: "a", now: march10East, calendar: east)
            store.markQuickSessionCompleted(now: march10East, calendar: east)

            let march10West = date(reader, day: 10, hour: 18)
            XCTAssertTrue(store.quickSessionCompletedToday(now: march10West, calendar: reader), "\(hours)h west")
            store.recordSession(drillID: "a", now: march10West, calendar: reader)
            XCTAssertEqual(store.streakCount, 1, "\(hours)h west: March 10 counted twice")

            let march11West = date(reader, day: 11, hour: 10)
            XCTAssertFalse(store.quickSessionCompletedToday(now: march11West, calendar: reader))
            XCTAssertEqual(store.currentStreak(now: march11West, calendar: reader), 1, "\(hours)h west")
            store.recordSession(drillID: "a", now: march11West, calendar: reader)
            XCTAssertEqual(store.streakCount, 2, "\(hours)h west")
            XCTAssertEqual(store.currentStreak(now: date(reader, day: 13, hour: 10), calendar: reader), 0)
        }
    }

    func testDayGapsCrossMonthsAndYears() {
        XCTAssertEqual(ProgressStore.days(from: "2026-02-28", to: "2026-03-01"), 1)
        XCTAssertEqual(ProgressStore.days(from: "2026-12-31", to: "2027-01-01"), 1)
        XCTAssertEqual(ProgressStore.days(from: "2026-03-11", to: "2026-03-10"), -1)
        XCTAssertNil(ProgressStore.days(from: "garbage", to: "2026-03-10"))
    }

    // MARK: - Stale membership cache (B2)

    /// A free week started and the app was opened once, then not again until
    /// after the trial converted. RevenueCat's launch cache is four days old
    /// and, judged against today, reads "not active". That is not a lapse.
    func testStaleCachedInactiveRecordDoesNotQueueChurnQuestion() {
        let service = SubscriptionService.shared
        service.consumeChurnMoment()
        let now = Date()
        let trialOn = MembershipSnapshot(isActive: true, isTrial: true, willRenew: true)
        let paidOn = MembershipSnapshot(isActive: true, isTrial: false, willRenew: true)

        service.observe(trialOn, answeredAt: now.addingTimeInterval(-8 * 86_400), now: now.addingTimeInterval(-8 * 86_400), defaults: defaults)
        service.observe(.none, answeredAt: now.addingTimeInterval(-4 * 86_400), now: now, defaults: defaults)
        XCTAssertNil(service.pendingChurnMoment, "a four-day-old cached record queued the churn question")

        // The network then says they paid: still nothing to ask.
        service.observe(paidOn, answeredAt: now, now: now, defaults: defaults)
        XCTAssertNil(service.pendingChurnMoment)

        // A fresh "not active" is a real departure and is still caught.
        service.observe(.none, answeredAt: now, now: now, defaults: defaults)
        XCTAssertEqual(service.pendingChurnMoment, .paidLapsed)
        service.consumeChurnMoment()
    }

    /// The real lapse, seen through the stale cache first: the baseline
    /// survives the cache, so the network answer still asks once.
    func testNetworkLapseAfterStaleCacheStillAsks() {
        let service = SubscriptionService.shared
        service.consumeChurnMoment()
        let now = Date()
        let trialOn = MembershipSnapshot(isActive: true, isTrial: true, willRenew: true)

        service.observe(trialOn, answeredAt: now.addingTimeInterval(-8 * 86_400), now: now.addingTimeInterval(-8 * 86_400), defaults: defaults)
        service.observe(.none, answeredAt: now.addingTimeInterval(-4 * 86_400), now: now, defaults: defaults)
        service.observe(.none, answeredAt: now, now: now, defaults: defaults)
        XCTAssertEqual(service.pendingChurnMoment, .trialLapsed)
        service.consumeChurnMoment()
    }

    // MARK: - The Minute's week (B6)

    /// Run with `-testRegion DE` (week starts Monday) to see the bug; in a
    /// Sunday-first region the two calendars already agree.
    func testMinuteWeekStartsOnTheDevicesFirstWeekday() {
        let device = Calendar.current
        XCTAssertEqual(Calendar.gregorianLocal.firstWeekday, device.firstWeekday)

        let reference = Date(timeIntervalSince1970: 1_773_100_000)
        let weekStart = device.dateInterval(of: .weekOfYear, for: reference)!.start
        let lastDayOfPreviousWeek = weekStart.addingTimeInterval(-3600)
        let store = SheepsheadMinuteStore(defaults: defaults)
        store.record(
            challenge: SheepsheadMinuteContent.challenge(for: lastDayOfPreviousWeek),
            answers: [true, true, true, true, true],
            now: lastDayOfPreviousWeek
        )

        XCTAssertEqual(store.completedThisWeek(now: weekStart.addingTimeInterval(3600)), 0,
                       "last week's result counted toward this week")
    }
}

